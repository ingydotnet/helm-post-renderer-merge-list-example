helm-post-renderer-merge-list-example
=====================================

Use a [YS](https://yamlscript.org) post-renderer for special values merge


## Synopsis

```
$ make test
VALUES_FILE=values2.yaml \
helm template cronjob --post-renderer=./ys-merge-env
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: release-name-cronjob
  labels:
    app: cronjob
    chart: cronjob-0.1.0
    release: release-name
    heritage: Helm
spec:
  schedule: 0 11 * * *
  startingDeadlineSeconds: null
  jobTemplate:
    spec:
      template:
        metadata:
          name: release-name-cronjob
        spec:
          restartPolicy: Never
          imagePullSecrets:
          - name: quay-sts
          containers:
          - name: release-name-cronjob
            imagePullPolicy: Always
            image: 'nginx:'
            args:
            - npm
            - start
            - foo_job
            env:
            - name: FOO
              value: new foo
            - name: BAR
              value: bar
            - name: BAZ
              value: new baz
```


## Description

This repo shows a solution for https://github.com/helm/helm/issues/3486 done in
a way that is completely customizable.

It was made to show an alternative to https://github.com/helm/helm/pull/30632.


## The Problem

The argument `--values=values2.yaml` option for `helm install` (or `helm
template` or `helm upgrade`) merges the data structure from the `values2.yaml`
file with the data structure from the chart's `values.yaml` file.

In [3486](https://github.com/helm/helm/issues/3486) some people wanted it to
"merge" sequences of mappings, resulting in a sequence of mappings where the
key `name` was used to determine how a mapping was added to the result
sequence.

This is a very special and specific kind of merge, and just one of countless
possible ways to merge/transform a data structure.

[30632](https://github.com/helm/helm/pull/30632) wants to change Helm's
internal YAML load/rendering algorithm to look for certain keys that trigger
this very specific merge algorithm.


## This Solution

This repo example uses a custom Helm post-renderer to achieve the specific
desired effect.

```
VALUES_FILE=values2.yaml \
helm template cronjob --post-renderer=./ys-merge-env
```

The `ys-merge-env` post-renderer uses a `VALUES_FILE` variable to indicate the
location of the YAML file to be merged in (`values2.yaml`).

The YS `list-merge` function that does the desired merging of lists looks like:

```yaml
defn list-merge(key list1 list2): !:vals
  reduce \(%1.assoc(%2.$key %2)) {}:
    list1 + list2
```


## Conclusion

Using a post-renderer is a good way to get desired special behaviors from Helm.

It doesn't require any core changes to Helm or to the way it interprets YAML.

YS is a powerful way to write custom post-renderers, but certainly not the only
way.


## Using YS

This repo's post-renderer starts with:

```
#!/usr/bin/env bash
source <(curl '-s' 'https://getys.org/run') "$@":
```

It installs the `ys` binary in `/tmp` the first time you run it.
This way, you don't need to even to pre-install `ys` for this to work.
Running the `make test` command here should just work.

If you want to pre-install `ys` you can do so like this:

```
curl -s https://getys.org/ys | bash
```

And then change the shebang line to:

```
#!/usr/bin/env ys-0
```

See <https://yamlscript.org/doc/install> for more info.


## See Also

* [HelmYS](https://yamlscript.org/helmys/) is a post-renderer that lets you
  use YS YAML for chart templates instead of Go templates.
  The result is much much cleaner and the templates are also 100% valid YAML
  and work with YAML tools like `yamllint`.
* [This repo](https://github.com/ingydotnet/helmys-hook-merge-list-example) is
  similar to this one.
  It uses HelmYS (in various interesting ways) to do the same thing.
