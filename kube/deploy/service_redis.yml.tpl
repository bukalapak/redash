---
apiVersion: v1
kind: Service
metadata:
  name: redis-$DOMAIN
spec:
  selector:
    app: redis-$DOMAIN
    domain: $DOMAIN
    env: $ENV
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379 
...
