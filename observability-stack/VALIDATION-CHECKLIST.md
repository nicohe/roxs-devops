# ✅ Day 56 - Validation Checklist

## Pre-Deployment Checklist

- [ ] Kubernetes cluster is running and accessible
- [ ] `kubectl` CLI is installed and configured
- [ ] Helm is installed (for Prometheus stack)
- [ ] At least 4 CPUs and 8GB RAM available
- [ ] Monitoring namespace exists or auto-install enabled

## Deployment Checklist

- [ ] Run `./scripts/setup-observability.sh` successfully
- [ ] All pods in `voting-app` namespace are Running
- [ ] All pods in `monitoring` namespace are Running
- [ ] Run `./scripts/verify-stack.sh` - all checks pass

## Prometheus Integration Checklist

- [ ] ServiceMonitors created in `voting-app` namespace
- [ ] Prometheus targets show all services as "UP"
  - http://localhost:30090/targets
  - Look for: vote-metrics, worker-metrics, result-metrics
- [ ] Metrics endpoints accessible:
  - Vote: `http://localhost:30080/metrics`
  - Worker: via internal service
  - Result: via internal service

## Grafana Dashboard Checklist

- [ ] Grafana accessible at http://localhost:30091
- [ ] Login successful (admin / admin123)
- [ ] Business Dashboard imported and visible
  - [ ] Total Votes gauge shows data
  - [ ] Voting Rate time series shows data
  - [ ] Votes Distribution pie chart shows data
- [ ] Technical Dashboard imported and visible
  - [ ] Request Rate shows RPS
  - [ ] Error Rate shows percentage
  - [ ] Response Time shows P50/P95/P99
  - [ ] CPU/Memory graphs show data
- [ ] Dashboards auto-refresh every 10s

## Alerting Checklist

- [ ] PrometheusRule `voting-app-alerts` created
- [ ] Prometheus alerts page accessible
  - http://localhost:30090/alerts
- [ ] Recording rules showing data:
  - [ ] `voting_app:availability:30d`
  - [ ] `voting_app:error_budget_remaining:30d`
  - [ ] `voting_app:request_rate:1m`

## Load Testing Checklist

- [ ] Vote service accessible at http://localhost:30080
- [ ] Result service accessible at http://localhost:30081
- [ ] Can cast votes manually
- [ ] Results update in real-time
- [ ] Run `./scripts/load-test-demo.sh`
  - [ ] Script completes successfully
  - [ ] Metrics visible in Grafana during test
  - [ ] No critical errors in logs

## End-to-End Validation

- [ ] Cast a vote at http://localhost:30080
- [ ] Vote appears in results at http://localhost:30081
- [ ] Vote increments `votes_total` metric in Prometheus
- [ ] Dashboard shows updated vote count
- [ ] No alerts triggered during normal operation

## Documentation Checklist

- [ ] README.md reviewed - architecture clear
- [ ] DIA56-GUIDE.md reviewed - can follow steps
- [ ] DIA56-DEMO-SCRIPT.md reviewed - demo flow understood
- [ ] IMPLEMENTATION-SUMMARY.md reviewed - deliverables clear

## Demo Preparation Checklist

- [ ] All port-forwards active (via `./scripts/port-forward.sh`)
- [ ] Browser tabs open:
  - [ ] http://localhost:30091 (Grafana Business Dashboard)
  - [ ] http://localhost:30091 (Grafana Technical Dashboard)
  - [ ] http://localhost:30090/targets (Prometheus Targets)
  - [ ] http://localhost:30090/alerts (Prometheus Alerts)
  - [ ] http://localhost:30080 (Vote App)
  - [ ] http://localhost:30081 (Results)
- [ ] Load test script ready to run
- [ ] Demo script (DIA56-DEMO-SCRIPT.md) printed or accessible

## Optional - Advanced Features

- [ ] Jaeger installed and accessible at http://localhost:16686
- [ ] Distributed tracing working
- [ ] ELK Stack installed (Elasticsearch + Kibana)
- [ ] Logs centralized in Kibana
- [ ] Custom alerts configured in Alertmanager
- [ ] Slack/PagerDuty integration for alerts

## Cleanup Checklist (After Demo)

- [ ] Stop port forwards: `pkill -f 'kubectl port-forward'`
- [ ] Delete voting-app: `kubectl delete namespace voting-app`
- [ ] (Optional) Delete monitoring: `kubectl delete namespace monitoring`
- [ ] (Optional) Delete cluster: `kind delete cluster --name observability`

---

## Troubleshooting Quick Reference

### Issue: Prometheus targets not showing
```bash
# Check ServiceMonitors have correct label
kubectl get servicemonitors -n voting-app -o yaml | grep "release: prometheus"

# Re-apply if needed
kubectl apply -f kubernetes/04-servicemonitors.yaml
```

### Issue: Dashboards not appearing in Grafana
```bash
# Check ConfigMaps exist
kubectl get configmap -n monitoring | grep voting

# Check labels
kubectl get configmap voting-business-dashboard -n monitoring -o yaml | grep grafana_dashboard

# Re-import if needed
kubectl delete configmap voting-business-dashboard voting-technical-dashboard -n monitoring
kubectl create configmap voting-business-dashboard --from-file=grafana-dashboards/business-dashboard.json -n monitoring
kubectl label configmap voting-business-dashboard grafana_dashboard=1 -n monitoring
```

### Issue: Pods not starting
```bash
# Check pod status
kubectl get pods -n voting-app

# Describe failed pod
kubectl describe pod <pod-name> -n voting-app

# Check logs
kubectl logs <pod-name> -n voting-app --previous
```

### Issue: Metrics show no data
```bash
# Verify endpoints are accessible
kubectl exec -n voting-app deployment/vote -- curl -s http://localhost:80/metrics | head -20

# Check Prometheus scrape config
kubectl get servicemonitor -n voting-app vote-metrics -o yaml

# Force Prometheus to reload
kubectl delete pod -n monitoring -l app.kubernetes.io/name=prometheus
```

---

**Status**: [ ] NOT STARTED | [ ] IN PROGRESS | [ ] ✅ COMPLETED

**Completion Date**: __________________

**Notes**:
_______________________________________________________________________
_______________________________________________________________________
_______________________________________________________________________
