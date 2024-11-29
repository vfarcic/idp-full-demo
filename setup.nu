#!/usr/bin/env nu

source scripts/kubernetes.nu
source scripts/crossplane.nu
source scripts/get-hyperscaler.nu
source scripts/ingress.nu
source scripts/github.nu
source scripts/kyverno.nu
source scripts/argocd.nu

rm --force .env

let hyperscaler = get-hyperscaler

let github_data = get_github_auth

create_kubernetes kind

apply_ingress kind nginx

kubectl create namespace a-team

apply_kyverno

apply_argocd "argocd.127.0.0.1.nip.io" false "nginx"

apply_crossplane $hyperscaler false true

apply_port $github_data.user

cp $"crossplane/($hyperscaler)-sql.yaml" apps/silly-demo-db.yaml

cp crossplane/app.yaml apps/silly-demo.yaml

open apps/silly-demo.yaml
    | upsert spec.parameters.image $"ghcr.io/($github_data.user)/idp-full-demo:FIXME:"
    | save apps/silly-demo.yaml --force

(
    docker login
        --username $github_data.user
        --password $github_data.token
        $"ghcr.io/($github_data.user)"
)

gh secret set REGISTRY_PASSWORD $"-b($github_data.token)"

start $"https://github.com/($github_data.user)/idp-full-demo/settings/actions"

print $"
Select (ansi yellow_bold)Read and write permissions(ansi reset) in the (ansi yellow_bold)Workflow permissions(ansi reset) section.
Click the (ansi yellow_bold)Save(ansi reset) button.
Press any key to continue.
"
input
