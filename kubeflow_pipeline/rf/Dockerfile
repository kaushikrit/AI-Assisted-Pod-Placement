FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY components ./components
COPY pipeline.py .

CMD ["bash"]