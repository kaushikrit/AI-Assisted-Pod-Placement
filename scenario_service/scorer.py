from scenario_service.features import extract_features


def compute_score(cu_node, du_node, scenario):

    f = extract_features(
        cu_node,
        du_node,
        scenario
    )

    latency = f["latency_ms"]

    budget = scenario["workload"]["latency_budget"]

    # =========================
    # VIOLATIONS
    # =========================

    violation_count = (
        f["cu_cpu_violation"] +
        f["cu_mem_violation"] +
        f["du_cpu_violation"] +
        f["du_mem_violation"]
    )

    if violation_count > 0:
        return 100

    # =========================
    # UTILIZATION
    # =========================

    cu_cpu_util = (
        f["cu_cpu_used_after"] /
        f["cu_cpu_capacity"]
    )

    du_cpu_util = (
        f["du_cpu_used_after"] /
        f["du_cpu_capacity"]
    )

    cu_mem_util = (
        f["cu_mem_used_after"] /
        f["cu_mem_capacity"]
    )

    du_mem_util = (
        f["du_mem_used_after"] /
        f["du_mem_capacity"]
    )

    avg_util = (
        cu_cpu_util +
        du_cpu_util +
        cu_mem_util +
        du_mem_util
    ) / 4

    # =========================
    # RESOURCE PENALTY
    # =========================

    resource_penalty = (
        avg_util * 35
    )

    # =========================
    # LATENCY PENALTY
    # =========================

    if latency <= budget:

        latency_penalty = (
            latency / budget
        ) * 10

    else:

        latency_penalty = min(
            35,
            10 + (
                (latency - budget) * 6
            )
        )

    # =========================
    # SAME NODE PENALTY
    # =========================

    same_node_penalty = 0

    if cu_node == du_node:

        same_node_penalty = 12

    # =========================
    # LOAD IMBALANCE
    # =========================

    load_difference = abs(
        f["cu_load"] -
        f["du_load"]
    )

    imbalance_penalty = (
        load_difference * 8
    )

    # =========================
    # CLUSTER BALANCE PENALTY
    # =========================

    balance_penalty = (
        (
            f["cpu_balance"] +
            f["mem_balance"]
        ) * 40
    )

    # =========================
    # SAME ZONE BONUS
    # =========================

    same_zone_bonus = 0

    if f["same_zone"] == 1:

        same_zone_bonus = -4

    # =========================
    # FINAL SCORE
    # =========================

    score = (
        balance_penalty +
        resource_penalty +
        latency_penalty +
        same_node_penalty +
        imbalance_penalty +
        same_zone_bonus
    )

    score = max(
        0,
        min(100, score)
    )

    return round(score, 4)
# ====================================
# EVALUATE ENTIRE SCENARIO
# ====================================

def evaluate_scenario(scenario):

    node_names = [
        n["name"]
        for n in scenario["nodes"]
    ]

    results = []

    best_score = float("inf")

    best_placement = None

    for cu_node in node_names:

        for du_node in node_names:

            features = extract_features(
                cu_node,
                du_node,
                scenario
            )

            score = compute_score(
                cu_node,
                du_node,
                scenario
            )

            result = {
                "scenario_id": scenario["scenario_id"],
                "difficulty": scenario["difficulty"],
                "cu_node": cu_node,
                "du_node": du_node,
                **features,
                "score": score
            }

            results.append(result)

            if score < best_score:

                best_score = score

                best_placement = {
                    "scenario_id": scenario["scenario_id"],
                    "difficulty": scenario["difficulty"],
                    "cu_node": cu_node,
                    "du_node": du_node,
                    **features,
                    "score": score
                }

    return {
        "scenario_id": scenario["scenario_id"],
        "best_score": best_score,
        "best_placement": best_placement,
        "all_results": results
    }