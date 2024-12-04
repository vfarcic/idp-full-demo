#!/usr/bin/env nu

def "main apply crossplane" [
    --hyperscaler = none,
    --app = false,
    --db = false,
    --github_user: string, # GitHub user
    --github_token: string, # GitHub token
] {

    mut project_id = ""

    helm repo add crossplane https://charts.crossplane.io/stable

    (
        helm upgrade --install crossplane crossplane/crossplane
            --namespace crossplane-system --create-namespace
            --wait
    )

    if $hyperscaler == "google" {

        gcloud auth login

        if PROJECT_ID in $env {
            $project_id = $env.PROJECT_ID
        } else {
            $project_id = $"dot-(date now | format date "%Y%m%d%H%M%S")"
            $env.PROJECT_ID = $project_id
            $"export PROJECT_ID=($project_id)\n" | save --append .env

            gcloud projects create $project_id

            start $"https://console.cloud.google.com/billing/enable?project=($project_id)"
    
            print $"
Select the (ansi yellow_bold)Billing account(ansi reset) and press the (ansi yellow_bold)SET ACCOUNT(ansi reset) button.
Press any key to continue.
"
            input

            let sa_name = "devops-toolkit"

            let sa = $"($sa_name)@($project_id).iam.gserviceaccount.com"
        
            (
                gcloud iam service-accounts create $sa_name
                    --project $project_id
            )

            sleep 2sec
        
            (
                gcloud projects add-iam-policy-binding
                    --role roles/admin $project_id
                    --member $"serviceAccount:($sa)"
            )
        
            (
                gcloud iam service-accounts keys
                    create gcp-creds.json --project $project_id
                    --iam-account $sa
            )
        
            (
                kubectl --namespace crossplane-system
                    create secret generic gcp-creds
                    --from-file creds=./gcp-creds.json
            )

        }

    }

    if $app {
        (
            kubectl apply
                --filename crossplane/config-dot-application.yaml
        )

    }

    if $db {

        if $hyperscaler == "google" {
            
            start $"https://console.cloud.google.com/marketplace/product/google/sqladmin.googleapis.com?project=($project_id)"
            
            print $"(ansi yellow_bold)
ENABLE(ansi reset) the API.
Press any key to continue.
"
            input

        }

        (
            kubectl apply
                --filename crossplane/config-dot-sql.yaml
        )
    }

    (
        kubectl apply
            --filename crossplane/provider-helm-incluster.yaml
    )

    (
        kubectl apply
            --filename crossplane/provider-kubernetes-incluster.yaml
    )

    print $"(ansi yellow_bold)Waiting for Crossplane providers to be deployed...(ansi reset)"

    sleep 60sec

    (
        kubectl wait
            --for=condition=healthy provider.pkg.crossplane.io
            --all --timeout 30m
    )

    if $hyperscaler == "google" {

        open crossplane/provider-config-google.yaml
            | upsert spec.projectID $project_id
            | save crossplane/provider-config-google.yaml --force

        kubectl apply --filename crossplane/provider-config-google.yaml

    }

    if ($github_user | is-not-empty) and ($github_token | is-not-empty) {

        {
            apiVersion: v1,
            kind: Secret,
            metadata: {
                name: github,
                namespace: crossplane-system
            },
            type: Opaque,
            stringData: {
                credentials: $"{\"token\":\"($github_token)\",\"owner\":\"($github_user)\"}"
            }
        }
            | to yaml
            | kubectl --namespace crossplane-system apply --filename -

        if $app {

            {
                apiVersion: "github.upbound.io/v1beta1",
                kind: ProviderConfig,
                metadata: {
                    name: default
                },
                spec: {
                    credentials: {
                        secretRef: {
                            key: credentials,
                            name: github,
                            namespace: crossplane-system,
                        },
                        source: Secret
                    }
                }
            }
                | to yaml
                | kubectl apply --filename -

        }

    }


}

def "main delete crossplane" [hyperscaler = none] {

    if $hyperscaler == "google" {

        let project_id = $env.PROJECT_ID

        gcloud projects delete $project_id --quiet

    }

}
