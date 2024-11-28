#!/usr/bin/env nu

source scripts/kubernetes.nu
source scripts/crossplane.nu
source scripts/get-hyperscaler.nu
source scripts/ingress.nu
source scripts/github.nu

rm --force .env

let hyperscaler = get-hyperscaler

let github_data = get_github_auth

create_kubernetes kind

apply_ingress kind nginx

kubectl create namespace a-team

apply_crossplane $hyperscaler false true

cp $"crossplane/($hyperscaler)-sql.yaml" apps/silly-demo-db.yaml

cp crossplane/app.yaml apps/silly-demo.yaml

open apps/silly-demo.yaml
    | upsert spec.parameters.image $"ghcr.io/($github_data.user)/idp-full-demo:FIXME:"
    | save apps/silly-demo.yaml --force


# GITHUB_NAME=$(gh repo view --json nameWithOwner \
#     --jq .nameWithOwner)
# echo "export GITHUB_NAME=$GITHUB_NAME" >> .env

# echo "# Open https://getport.io and *Login*" | gum format
# gum input --placeholder "Press the enter key to continue."

# PORT_CLIENT_ID=$(gum input --placeholder "Port Client ID" --value "$PORT_CLIENT_ID")
# echo "export PORT_CLIENT_ID=$PORT_CLIENT_ID" >> .env

# gh secret set PORT_CLIENT_ID --body $PORT_CLIENT_ID \
#     --app actions --repos $GITHUB_NAME

# PORT_CLIENT_SECRET=$(gum input --placeholder "Port Client ID" --value "$PORT_CLIENT_SECRET" --password)
# echo "export PORT_CLIENT_ID=$PORT_CLIENT_ID" >> .env

# gh secret set PORT_CLIENT_SECRET --body $PORT_CLIENT_SECRET \
#     --app actions --repos $GITHUB_NAME

# echo "## Install Port's GitHub app (https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/git/github/#installation)." \
#     | gum format
# gum input --placeholder "Press the enter key to continue."

# kubectl apply \
#     --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# kubectl create namespace a-team

# kubectl --namespace a-team apply \
#     --filename crossplane-config/db-secret.yaml

# helm upgrade --install port-k8s-exporter port-k8s-exporter \
#     --repo https://port-labs.github.io/helm-charts \
#     --namespace port-k8s-exporter --create-namespace \
#     --set secret.secrets.portClientId=$PORT_CLIENT_ID \
#     --set secret.secrets.portClientSecret=$PORT_CLIENT_SECRET \
#     --set stateKey="k8s-exporter"  \
#     --set createDefaultResources=false \
#     --set "extraEnv[0].name"="dot" \
#     --set "extraEnv[0].value"=dot --wait

# echo '* Open https://app.getport.io/settings/data-sources in a browser
# * Select `k8s-exporter`
# * Add `crdsToDiscover: .metadata.ownerReferences[0].kind == "CompositeResourceDefinition" and .spec.scope == "Namespaced"`
# * Click the `Save & Resync` button.
# * Close the popup' \
#     | gum format
# gum input --placeholder "Press the enter key to continue."

# kubectl apply --filename crossplane-config/dot-sql.yaml

# kubectl apply --filename crossplane-config/dot-app.yaml

# kubectl apply --filename crossplane-config/dot-kubernetes.yaml

# helm upgrade --install argocd argo-cd \
#     --repo https://argoproj.github.io/argo-helm \
#     --namespace argocd --create-namespace \
#     --values argocd-values.yaml --wait

# yq --inplace \
#     ".spec.source.repoURL = \"https://github.com/$GITHUB_NAME\"" \
#     argocd-app.yaml

# kubectl apply --filename argocd-app.yaml

# echo "## Which Hyperscaler do you want to use?" | gum format
# echo 'By choosing `none`, resources will not be created in any of the hyperscalers, but the rest of the demo will still work.' | gum format
# HYPERSCALER=$(gum choose "google" "aws" "azure" "none")
# echo "export HYPERSCALER=$HYPERSCALER" >> .env

# if [[ "$HYPERSCALER" == "google" ]]; then

#     PROJECT_ID=dot-$(date +%Y%m%d%H%M%S)
#     echo "export PROJECT_ID=$PROJECT_ID" >> .env

#     gcloud auth login

#     gcloud projects create ${PROJECT_ID}

#     echo "## Open https://console.cloud.google.com/billing/enable?project=$PROJECT_ID in a browser and set the *billing account*" \
#         | gum format
#     gum input --placeholder "Press the enter key to continue."

#     echo "## Open https://console.cloud.google.com/apis/library/sqladmin.googleapis.com?project=${PROJECT_ID} in a browser and *ENABLE the API*." \
#         | gum format
#     gum input --placeholder "Press the enter key to continue."

#     export SA_NAME=devops-toolkit

#     export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

#     gcloud iam service-accounts create $SA_NAME \
#         --project $PROJECT_ID

#     export ROLE=roles/admin

#     gcloud projects add-iam-policy-binding \
#         --role $ROLE $PROJECT_ID --member serviceAccount:$SA

#     gcloud iam service-accounts keys create gcp-creds.json \
#         --project $PROJECT_ID --iam-account $SA

#     kubectl --namespace crossplane-system \
#         create secret generic gcp-creds \
#         --from-file creds=./gcp-creds.json

#     kubectl wait \
#         --for=condition=healthy provider.pkg.crossplane.io \
#         --all --timeout=600s

#     echo "apiVersion: gcp.upbound.io/v1beta1
# kind: ProviderConfig
# metadata:
#   name: default
# spec:
#   projectID: $PROJECT_ID
#   credentials:
#     source: Secret
#     secretRef:
#       namespace: crossplane-system
#       name: gcp-creds
#       key: creds" | kubectl apply --filename -

# elif [[ "$HYPERSCALER" == "aws" ]]; then

#     AWS_ACCESS_KEY_ID=$(gum input \
#         --placeholder "AWS Access Key ID" \
#         --value "$AWS_ACCESS_KEY_ID")
#     echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env
    
#     AWS_SECRET_ACCESS_KEY=$(gum input \
#         --placeholder "AWS Secret Access Key" \
#         --value "$AWS_SECRET_ACCESS_KEY" --password)
#     echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env

#     AWS_ACCOUNT_ID=$(gum input --placeholder "AWS Account ID" \
#         --value "$AWS_ACCOUNT_ID")
#     echo "export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> .env

#     echo "[default]
# aws_access_key_id = $AWS_ACCESS_KEY_ID
# aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
# " >aws-creds.conf

#     kubectl --namespace crossplane-system \
#         create secret generic aws-creds \
#         --from-file creds=./aws-creds.conf

#     kubectl wait \
#         --for=condition=healthy provider.pkg.crossplane.io \
#         --all --timeout=600s

#     kubectl apply \
#         --filename crossplane-config/provider-config-aws.yaml

# elif [[ "$HYPERSCALER" == "azure" ]]; then

#     az login

#     SUBSCRIPTION_ID=$(az account show --query id -o tsv)

#     az ad sp create-for-rbac --sdk-auth --role Owner \
#         --scopes /subscriptions/$SUBSCRIPTION_ID \
#         | tee azure-creds.json

#     kubectl --namespace crossplane-system \
#         create secret generic azure-creds \
#         --from-file creds=./azure-creds.json

#     kubectl wait \
#         --for=condition=healthy provider.pkg.crossplane.io \
#         --all --timeout=600s

#     kubectl apply \
#         --filename crossplane-config/provider-config-azure.yaml

# fi

# git add .

# git commit -m "Setup"

# git push