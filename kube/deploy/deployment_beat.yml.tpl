---
apiVersion: extensions/v1beta1 
kind: Deployment
metadata:
  name: $DOMAIN-beat-$ENV
spec:
  selector:
    matchLabels:
      app: $DOMAIN-beat
  replicas: 1
  revisionHistoryLimit: 0
  template:
    metadata:
      labels:
        app: $DOMAIN-beat
        domain: $DOMAIN
        superdomain: redash
        env: $ENV
    spec:
      imagePullSecrets:
      - name: blregistry
      volumes:
      - name: worker-tmp-volume
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
        resources:
          requests:
            memory: "500Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        command:
          - envconsul
          - -prefix=redash/shared
          - -prefix=redash/$DOMAIN
          - -prefix=redash/$DOMAIN-scalable
          - /home/redash/.local/bin/celery 
          - --app=redash.worker 
          - beat
          - -lDEBUG
          - --pidfile=/tmp/beat_pid
        volumeMounts:
        - mountPath: /tmp
          name: worker-tmp-volume
...
