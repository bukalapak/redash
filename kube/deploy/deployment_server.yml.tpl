---
apiVersion: extensions/v1beta1 
kind: Deployment
metadata:
  name: $DOMAIN-server-$ENV
spec:
  selector:
    matchLabels:
      app: $DOMAIN-server
  replicas: $SERVER_REPLICAS 
  revisionHistoryLimit: 0
  template:
    metadata:
      labels:
        app: $DOMAIN-server
        domain: $DOMAIN
        superdomain: redash
        env: $ENV
    spec:
      imagePullSecrets:
      - name: blregistry
      volumes:
      - name: server-tmp-volume
        emptyDir:
          medium: Memory
      nodeSelector:
        env: $NODE_SELECTOR
      containers:
      - name: consul
        image: consul:0.7.3
        ports:
          - containerPort: 8300
          - containerPort: 8301
          - containerPort: 8302
          - containerPort: 8400
          - containerPort: 8500
          - containerPort: 8600
        env:
          - name: CONSUL_LOCAL_CONFIG
            value: "{\"leave_on_terminate\": true}"
          - name: CONSUL1
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: node1
          - name: CONSUL2
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: node2
          - name: CONSUL3
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: node3
          - name: CONSUL_ENCRYPT
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: encrypt
        command:
          - consul
          - agent
          - -datacenter=biznet
          - -data-dir=/tmp/consul
          - -join=$(CONSUL1)
          - -join=$(CONSUL2)
          - -join=$(CONSUL3)
          - -encrypt=$(CONSUL_ENCRYPT)
      - name: redash
        image: $IMAGE_REPOSITORY:$IMAGE_VERSION
        imagePullPolicy: Always
        ports:
        - containerPort: 5000
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "3Gi"
            cpu: "1500m"
        command:
          - envconsul
          - -prefix=redash/shared
          - -prefix=redash/$DOMAIN
          - -prefix=redash/$DOMAIN-scalable
          - /home/redash/.local/bin/gunicorn 
          - -b=0.0.0.0:5000 
          - --name=redash 
          - -w=10
          - --max-requests=1000
          - --timeout=100
          - --log-level=INFO
          - --log-file=/tmp/gunicorn_log
          - --pid=/tmp/gunicorn_pid
          - redash.wsgi:app
        livenessProbe:
          tcpSocket:
            port: 5000
          initialDelaySeconds: 20
          periodSeconds: 5 
          timeoutSeconds: 10 
        volumeMounts:
        - mountPath: /tmp
          name: server-tmp-volume
...
