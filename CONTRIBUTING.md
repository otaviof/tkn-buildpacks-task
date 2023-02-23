`tkn-buildpacks-task`
---------------------

This project is structured as a Helm Chart repository, therefore you can rollout using the standard approach. In other words:


```bash
helm install .
# or
helm template . |kubectl apply -f -
```

In order to contribute, you will need the following tools installed:

- [`helm/helm`][githubHelm]: transforms a template into the actual Kubernetes resources, testing and making changes to this repository will require `helm` installed
- [`kubectl` (KinD)][sigsKinD]: make sure you have a Kubernetes instance available and `kubectl` ready to use
- [`tektoncd/pipeline`][githubTektonPipeline]: in order to install and test, Tekton Pipeline needs to be installed
- [`tektoncd/cli`][githubTektonCLI]: the `tkn` is employed as during testing
- [`nektos/act`][githubNektosAct] (optional): runs GitHub Actions workflows locally using the local changes, simulating the whole CI workflow with containers

# Scripts

The Bash scripts employed on the Task steps are kept in the scripts directory, where later on `helm` renders the Tekton Task resource embeding the scripts. They can be consumed as a regular executable command-line.

Keeping the scripts in a [dedicated folder](./scripts/) allows flexibility to develop and test, makes possible to add integration testing where the scripts are exercised in a controlled environment.

# Testing

All project automation is concentrated on the [`Makefile`](./Makefile), feel free to add more targets as more tools become necessary.

The tests are written with Bash using [BATS framework][batsCore], represented on this repository as [submodules](./.gitmodules), make sure you run the following commands after cloning the repository:

```bash
git submodule init
git submodule update
```

## Integration

Integration tests are in [this folder](./test/integration), call the following target to execute them:

```bash
make test-integration
```

## E2E

End-to-end tests are in [this folder](./test/e2e), the tests require a Kubernetes instance, Tekton and more, please consider the [GitHub Action workflow](./.github/workflows/test.yaml) for more details.

Run the end-to-end tests with:

```bash
make test-e2e
```

## GitHub Actions

Continuous integration tests are exercised with GitHub Actions, which you can also run on your own workstation with [`act`][githubNektosAct]. The testing environment is being created using [setup-tekton][otaviofSetupTekton] action to rollout Kubernetes related dependencies.

To run it locally execute:

```bash
act
```

[batsCore]: https://github.com/bats-core/bats-core
[githubHelm]: https://github.com/helm/helm
[sigsKinD]: https://kind.sigs.k8s.io
[githubTektonCLI]: https://github.com/tektoncd/cli
[githubNektosAct]: https://github.com/nektos/act
[githubTektonPipeline]: https://github.com/tektoncd/pipeline
[otaviofSetupTekton]: https://github.com/otaviof/setup-tekton