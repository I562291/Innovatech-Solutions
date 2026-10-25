FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
COPY templates templates

EXPOSE 8080
CMD ["python", "app.py"]

# no cache dir gebruiken we om ervoor te zorgen dat pip geen cache gebruikt bij het installeren van de vereisten, wat de image kleiner maakt.