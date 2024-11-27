#!/usr/bin/env nu

def --env get_github_auth [] {

    mut github_token = ""
    if "GITHUB_TOKEN" not-in $env {
        $github_token = input $"(ansi green_bold)Enter GitHub token:(ansi reset)"
    } else {
        $github_token = $env.GITHUB_TOKEN
    }
    $"export GITHUB_TOKEN=($github_token)\n" | save --append .env

    mut github_user = ""
    if "GITHUB_USER" not-in $env {
        $github_user = input $"(ansi green_bold)Enter GitHub user or organization where you forked the repo:(ansi reset)"
    } else {
        $github_user = $env.GITHUB_USER
    }
    $"export GITHUB_USER=($github_user)\n" | save --append .env

    {github_user: $github_user, github_token: $github_token}

}
