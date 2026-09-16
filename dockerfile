FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && apt-get install -y nginx

RUN pip install --no-cache-dir -r requirements.txt

COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY . . 

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:5000 app:app & nginx -g 'daemon off;'"]