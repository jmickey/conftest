#!/usr/bin/env bats

@test "Not fail when testing a service with a warning" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml
  [ "$status" -eq 0 ]
}

@test "Not fail when passed an explicit blank filename" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml ""
  [ "$status" -eq 0 ]
}

@test "Fail when testing a deployment with root containers" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/deployment.yaml
  [ "$status" -eq 1 ]
}

@test "Fail when testing a service with warnings" {
  run ./conftest test --fail-on-warn -p examples/kubernetes/policy examples/kubernetes/service.yaml
  [ "$status" -eq 1 ]
}

@test "Fail when testing with no policies path" {
  run ./conftest test -p internal/ examples/kubernetes/deployment.yaml
  [ "$status" -eq 1 ]
}

@test "Pass when testing a blank namespace" {
  run ./conftest test --namespace notpresent -p examples/kubernetes/policy examples/kubernetes/deployment.yaml
  [ "$status" -eq 0 ]
}

@test "when testing a YAML document via stdin, default parser should be yaml if no input flag is passed" {
  run ./conftest test -p examples/kubernetes/policy - < examples/kubernetes/service.yaml
  [ "$status" -eq 0 ]
}

@test "Pass when testing a YAML document via stdin" {
  run ./conftest test -i yaml -p examples/kubernetes/policy - < examples/kubernetes/service.yaml
  [ "$status" -eq 0 ]
}

@test "Fail due to picking up settings from configuration file" {
  cd examples/configfile
  run ../../conftest test deployment.yaml
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Containers must not run as root" ]]
}

@test "Has version flag" {
  run ./conftest --version
  [ "$status" -eq 0 ]
}

@test "Test command with multiple input type" {
  run ./conftest test examples/traefik/traefik.toml examples/kubernetes/service.yaml -p examples/kubernetes/policy 
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Found service hello-kubernetes but services are not allowed" ]]
}

@test "Test command has trace flag" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml --trace
  [ "$status" -eq 0 ]
  [[ "$output" =~ "data.kubernetes.is_service" ]]
}

@test "Test command with json output and trace flag" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml -o json --trace
  [ "$status" -eq 0 ]
  [[ "$output" =~ "data.kubernetes.is_service" ]]
}

@test "Test command with tap output and trace flag" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml -o tap --trace
  [ "$status" -eq 0 ]
  [[ "$output" =~ "data.kubernetes.is_service" ]]
}

@test "Test command with table output and trace flag" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml -o table --trace
  [ "$status" -eq 0 ]
  [[ "$output" =~ "| trace   | examples/kubernetes/service.yaml | Enter data.main.deny = _       |" ]]
}

@test "Test command with all namespaces flag" {
  run ./conftest test -p examples/docker/policy examples/docker/Dockerfile --all-namespaces
  [ "$status" -eq 1 ]
  [[ "$output" =~ "blacklisted image found [\"openjdk:8-jdk-alpine\"]" ]]
  [[ "$output" =~ "blacklisted commands found [\"apk add --no-cache python3 python3-dev build-base && pip3 install awscli==1.18.1\"]" ]]
}

@test "Verify command has trace flag" {
    run ./conftest verify --policy ./examples/kubernetes/policy --trace
  [ "$status" -eq 0 ]
  [[ "$output" =~ "data.kubernetes.is_service" ]]
}

@test "Fail when verifing with no policies path" {
  run ./conftest verify -p internal/
  [ "$status" -eq 1 ]
}

@test "Has help flag" {
  run ./conftest --help
  [ "$status" -eq 0 ]
}

@test "Allow .rego files in the policy flag" {
  run ./conftest test -p examples/terraform/policy/base.rego examples/terraform/gke-show.json
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Terraform plan will change prohibited resources in the following namespaces: google_iam, google_container" ]]
}

@test "Can parse tf files" {
  run ./conftest test -p examples/terraform/policy/gke.rego examples/terraform/gke.tf
  [ "$status" -eq 0 ]
}

@test "Can parse toml files" {
  run ./conftest test -p examples/traefik/policy examples/traefik/traefik.toml
  [ "$status" -eq 1 ]
}

@test "Can parse edn files" {
  run ./conftest test -p examples/edn/policy examples/edn/sample_config.edn
  [ "$status" -eq 1 ]
}

@test "Can parse xml files" {
  run ./conftest test -p examples/xml/policy examples/xml/pom.xml
  [ "$status" -eq 1 ]
  [[ "$output" =~ "--- maven-plugin must have the version: 3.6.1" ]]
}

@test "Can parse hocon files" {
  run ./conftest test -p examples/hocon/policy examples/hocon/hocon.conf -i hocon
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Play http server port should be 9000" ]]
}

@test "Can parse vcl files" {
  run ./conftest test -p examples/vcl/policy examples/vcl/varnish.vcl
  [ "$status" -eq 1 ]
  [[ "$output" =~ "default backend port should be 8080" ]]
}

@test "Can parse multi-type files" {
  run ./conftest test -p examples/multitype/policy examples/multitype/deployment.yaml examples/multitype/grafana.ini
  [ "$status" -eq  1 ]
  [[ "$output" =~ "Port should be" ]]
}

@test "Can parse nested files with name overlap (first)" {
  run ./conftest test -p examples/nested/policy --namespace group1 examples/nested/data.json
  [ "$status" -eq 1 ]
}

@test "Can parse nested files with name overlap (second)" {
  run ./conftest test -p examples/nested/policy --namespace group2 examples/nested/data.json
  [ "$status" -eq 1 ]
}

@test "Can parse cue files" {
  run ./conftest test -p examples/cue/policy examples/cue/deployment.cue
  [ "$status" -eq 1 ]
  [[ "$output" =~ "The image port should be 8080 in deployment.cue. you got : 8081" ]]
}

@test "Can parse ini files" {
  run ./conftest test -p examples/ini/policy examples/ini/grafana.ini
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Users should verify their e-mail address" ]]
}

@test "Can parse hcl2 files" {
  run ./conftest test -p examples/hcl2/policy examples/hcl2/terraform.tf
  [ "$status" -eq 1 ]
  [[ "$output" =~ "ALB \`my-alb-listener\` is using HTTP rather than HTTP" ]]
}

@test "Can parse stdin with input flag" {
  run bash -c "cat examples/ini/grafana.ini | ./conftest test -p examples/ini/policy --input ini -"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Users should verify their e-mail address" ]]
  [[ "$output" != *"Basic auth should be enabled"* ]]
}

@test "Using -i/--input should force the chosen parser and fail the rego policy" {
  run ./conftest test -p examples/terraform/policy/gke.rego examples/terraform/gke.tf -i ini
  [ "$status" -eq 1 ]
}

@test "Can combine configs and reference by file" {
  run ./conftest test -p examples/terraform/policy/gke_combine.rego examples/terraform/gke.tf --combine -i hcl1
  [ "$status" -eq 0 ]
}

@test "Can parse docker files" {
  run ./conftest test -p examples/docker/policy examples/docker/Dockerfile
  [ "$status" -eq 1 ]
  [[ "$output" =~ "blacklisted image found [\"openjdk:8-jdk-alpine\"]" ]]
}

@test "Can disable color" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/service.yaml --no-color
  [ "$status" -eq 0 ]
  [[ "$output" != *"[33m"* ]]
}

@test "Output results only once" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/deployment.yaml
  count="${#lines[@]}"
  [ "$count" -eq 8 ]
}

@test "Can verify rego tests" {
  run ./conftest verify --policy ./examples/kubernetes/policy
  [ "$status" -eq 0 ]
  [[ "$output" =~ "PASS: 4/4" ]]
}

@test "Can parse inputs with 'conftest parse'" {
  run ./conftest parse examples/docker/Dockerfile
  [ "$status" -eq 0 ]
  [[ "$output" =~ "\"Cmd\": \"from\"" ]]
}

@test "Can output tap format in test command" {
  run ./conftest test -p examples/kubernetes/policy/ -o tap examples/kubernetes/deployment.yaml
  [[ "$output" =~ "not ok" ]]
}

@test "Can output tap format in verify command" {
  run ./conftest verify -p examples/kubernetes/policy/ -o tap
  [[ "$output" =~ "ok" ]]
}

@test "Can output table format in test command" {
  run ./conftest test -p examples/kubernetes/policy/ -o table examples/kubernetes/deployment.yaml
  [[ "$output" =~ "failure" ]]
}

@test "Can output table format in verify command" {
  run ./conftest verify -p examples/kubernetes/policy/ -o table
  [[ "$output" =~ "success" ]]
}

@test "Multi-file tests correctly fail when last file is fine" {
  run ./conftest test -p examples/kubernetes/policy examples/kubernetes/deployment.yaml examples/kubernetes/service.yaml
  [ "$status" -eq 1 ]
}

@test "Fail when unit test rego" {
  run ./conftest verify -p examples/traefik/policy
  [ "$status" -eq 1 ]
}

@test "Can load data along with rego policies" {
  run ./conftest test -p examples/data/policy -d examples/data/exclusions examples/data/service.yaml
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Cannot expose one of the following ports" ]]
}

@test "Can load data in unit tests" {
  run ./conftest verify -p examples/data/policy -d examples/data/exclusions examples/data/service.yaml
  [ "$status" -eq 0 ]
  [[ "$output" =~ "PASS" ]]
}

@test "Can update policies in test command" {
  run ./conftest test --update https://raw.githubusercontent.com/instrumenta/conftest/master/examples/compose/policy/deny.rego examples/compose/docker-compose.yml
  rm -rf policy/deny.rego
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No images tagged latest" ]]
}

@test "Can download or symlink plugins" {
  run ./conftest plugin install examples/plugins/kubectl/
  [ "$status" -eq 0 ]
  run ./conftest kubectl
  [ "$status" -eq 0 ]
}
