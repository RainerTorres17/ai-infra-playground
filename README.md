# MLflow Serving Stack
A lightweight, end-to-end stack for deploying and monitoring predictive models, statistical or machine learning-based, with integrated experiment tracking and observability. It includes configurations for deployments on both minikube and EKS.

- Infrastructure provisioned with **Terraform** on **AWS EKS**
- Model tracking and registry powered by **MLflow**
- Serving via **FastAPI**
- Monitoring with **Prometheus + Grafana**
- Locally tested with Minikube

<img width="1500" height="264" alt="Screenshot 2025-10-14 at 6 30 19 PM" src="https://github.com/user-attachments/assets/f43b7e1b-0552-42e2-8dd6-e9fa94e1cdf3" />

<img width="1472" height="690" alt="Screenshot 2025-10-14 at 6 29 43 PM" src="https://github.com/user-attachments/assets/6bdcd7a0-ecb6-44a4-b789-59ed70a2cb3a" />

---

## Training and Experiment Tracking
Each training job registers a new model version in MLflow. The first run promotes a model to the `@prod` alias automatically for serving. The consecutive runs can be promoted to prod under the condition that their SMAPE score is lower than the current production model.

<img width="2543" height="782" alt="Screenshot 2025-10-14 at 5 51 23 PM" src="https://github.com/user-attachments/assets/a0a87b54-5481-49e0-a484-fdc4cc6e22c8" />


*Notes:*
For local testing the training data is included in folder with the training script. The docker image used for the training job will include that training data file which can then be directly refrenced in the training job manifest where the script is called. If running on EKS update the environment variables to include your S3 bucket with the training data.

---

## Model Serving
Models are served via a FastAPI app that loads the latest `@prod` version from MLflow. I created a local streamlit application that makes api calls to the hosted model to simulate a realistic use case.

<img width="823" height="1083" alt="Screenshot 2025-10-14 at 5 59 40 PM" src="https://github.com/user-attachments/assets/a2bd91ae-4f5d-434d-a974-b9280990d11e" /><img width="805" height="1074" alt="Screenshot 2025-10-14 at 5 53 08 PM" src="https://github.com/user-attachments/assets/97d79eb3-f85e-4d7b-9d71-a86a0ad398fb" />

---

## Monitoring and Observability

The system integrates Prometheus and Grafana for monitoring model and API performance. Metrics are exposed via /metrics endpoint and discovered by a ServiceMonitor.

<img width="2543" height="782" alt="Screenshot 2025-10-14 at 5 49 31 PM" src="https://github.com/user-attachments/assets/464ed9c2-6bde-42b4-8614-1ec371c67e02" /><img width="2543" height="782" alt="Screenshot 2025-10-14 at 5 50 11 PM" src="https://github.com/user-attachments/assets/5f845da6-6c2c-4440-b36c-e6dd653def7e" />


---

## Deployment (Minikube and EKS)

The system can be tested locally using Minikube. Make sure to push the images for serving and training scripts to the Minikube node and then apply all the manifest.

For EKS all infrastructure is managed entirely through Terraform. Update the tfvars with your preferred configurations and GitHub repo to allow access to workflows.

Current cloud infrastructure set up:
  - EKS in public subnet for cost efficiency
  - Helm installs monitoring stack
  - Internal communication via ClusterIP
  - Access via kubectl port-forward

---

## Future Improvements

-	Replace ARIMA with ML model (e.g., regression or Prophet)
-	Add GitHub Actions CI/CD pipeline
-	Add ingress/ALB for public API access
-	Convert K8s manifest to helm charts for easier deployment
