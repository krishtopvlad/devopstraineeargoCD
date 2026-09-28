## Файл: $f
```
apiVersion: v1
kind: Service
metadata:
  name: apache-service
spec:
  type: NodePort
  selector:
    app: apache
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 80
      nodePort: 30081
```

## Файл: $f
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  labels:
    app: apache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
        - name: apache
          image: httpd:alpine
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"             
          ports:
            - containerPort: 80
              
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5

          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5

          startupProbe:
            httpGet:
              path: /
              port: 80
            failureThreshold: 30
            periodSeconds: 10



```

## Файл: $f
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 80
      nodePort: 30080
      ```

## Файл: $f
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  resources:
    requests:
      storage: 500Mi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  

```

## Файл: $f
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf : |
    upstream redblue{
            server 127.0.0.1:8081;
            server 127.0.0.1:8082;
        }

    server {
        listen       80;
        listen  [::]:80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        location /google {
            return 301 https://www.google.com;
        }

    
        location /redblue{
            proxy_pass http://redblue/;
            # Запрещаем браузеру сохранять эту страницу в кэш
            add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";

          # Гарантируем, что прокси не будет кэшировать ответы бэкендов
            proxy_buffering off;
        }

        location /music {
            root /usr/share/nginx/html;
            autoindex on;
        }

        location /pictures {
            root /usr/share/nginx/html;
            autoindex on;   
        }
    }

    server {
        listen 8081;
        location / {
            root /usr/share/nginx/html/red;
            index index.html;

        }
    }

    server {
        listen 8082;
        location / {
            root /usr/share/nginx/html/blue;
            index index.html;

        }
    }
```

## Файл: $f
```
prometheus:
  enabled: false


loki:
  enabled: true
  isDefault: true
  url: http://{{(include "loki.serviceName" .)}}:{{ .Values.loki.service.port }}
  readinessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 45
  livenessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 45
  datasource:
    jsonData: "{}"
    uid: ""
  image:
    tag: 2.9.11
  persistence:
    enabled: true
    storageClassName: local-path
    size: 5Gi

promtail:
  enabled: true
  config:
    logLevel: info
    serverPort: 3101
    clients:
      - url: http://{{ .Release.Name }}:3100/loki/api/v1/push

grafana:
  enabled: false 

```

## Файл: $f
```
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx
  namespace: app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

## Файл: $f
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      volumes:
        - name: nginx-config-volume
          configMap:
            name: nginx-config
        - name: nginx-storage
          persistentVolumeClaim:
            claimName: nginx-pvc 

            
      initContainers:
        - name: init-pvc-content
          image: busybox:1.36
          command:
            - sh
            - -c
            - 'echo "<h1>Hello from PVC!</h1>" > /usr/share/nginx/html/pvc/index.html'
          volumeMounts:
            - name: nginx-storage
              mountPath: /usr/share/nginx/html/pvc


      containers:
        - name: nginx
          image: marmeladkk/nginx-image:version-4
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"             
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-config-volume
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
            - name: nginx-storage
              mountPath: /usr/share/nginx/html/pvc
              
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5

          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5

          startupProbe:
            httpGet:
              path: /
              port: 80
            failureThreshold: 30
            periodSeconds: 10



```

## Файл: $f
```

```

## Файл: $f
```
```

## Файл: $f
```
#!/bin/bash

# Целевой URL
URL="http://10.38.89.249:30080/redblue"

# Количество параллельных запросов в одной "волне"
BATCH_SIZE=100

# Интервал между волнами (в секундах). 0.1 = 100 мс
INTERVAL=0.1

echo "Запуск нагрузки на $URL"
echo "Волна: $BATCH_SIZE запросов каждые $INTERVAL сек."
echo "Для остановки нажмите Ctrl+C"
echo "----------------------------------------"

# Счетчик волн
WAVE=0

while true; do
    WAVE=$((WAVE + 1))
    
    # Запускаем пачку запросов в фоне
    for ((i=1; i<=BATCH_SIZE; i++)); do
        curl -s "$URL" > /dev/null &
    done
    
    echo "Волна #$WAVE отправлена (PID последнего: $!)"
    
    # Ждем указанный интервал
    sleep $INTERVAL
done```

## Файл: $f
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Red Background</title>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            background-color: red;
        }
    </style>
</head>
<body>
</body>
</html>```

## Файл: $f
```
FROM nginx:alpine

COPY /pictures /usr/share/nginx/html/pictures
COPY /music /usr/share/nginx/html/music
COPY /index.html /usr/share/nginx/html/index.html

COPY /red /usr/share/nginx/html/red
COPY /blue /usr/share/nginx/html/blue

COPY stress-test.sh /usr/local/bin/stress-test.sh
RUN chmod +x /usr/local/bin/stress-test.sh
```

## Файл: $f
```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>

<h2>My part of Nginx:</h2>

<a href="/redblue">Redblue(proxy_pass)</a>
<a href="/google">Google(redirect)</a>
<a href="/music/">Music</a>
<a href="/pictures/">Pictures</a>
<a href="/pvc/">PVC Page</a>


</body>
</html>
```

## Файл: $f
```
upstream redblue{
        server 127.0.0.1:8081;
        server 127.0.0.1:8082;
    }

server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location /google {
        return 301 https://www.google.com;
    }

 
    location /redblue{
        proxy_pass http://redblue/;
        # Запрещаем браузеру сохранять эту страницу в кэш
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";

	    # Гарантируем, что прокси не будет кэшировать ответы бэкендов
        proxy_buffering off;
    }

    location /music {
        root /usr/share/nginx/html;
        autoindex on;
    }

    location /pictures {
        root /usr/share/nginx/html;
        autoindex on;   
    }
}

server {
    listen 8081;
    location / {
        root /usr/share/nginx/html/red;
        index index.html;

    }
}

server {
    listen 8082;
    location / {
        root /usr/share/nginx/html/blue;
        index index.html;

    }
}


```

## Файл: $f
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Red Background</title>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            background-color: blue;
        }
    </style>
</head>
<body>
</body>
</html>```

