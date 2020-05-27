# Writing RSpec tests for charts

The following are notes and conventions used for creating RSpec tests for the
GitLab chart.

## Generating YAML from the chart

Much of the testing of the chart is that it generates the correct YAML
structure given a number of [chart inputs](#chart-inputs). This is done using
the HelmTemplate class as in the following:

```ruby
obj = HelmTemplate.new(values)
```

The resulting `obj` encodes the YAML documents returned by the `helm template`
command indexed by the Kubernetes object and the object name. This indexed
valued is used by most of the methods to locate values within the YAML.

For example:

```ruby
obj.dig('ConfigMap/gitlab-gitaly', 'data', 'config.toml.erb')
```

This will return the contents of the `config.toml.erb` file contained in the
`gitlab-gitaly` ConfigMap.

## Chart inputs

The input parameter to the `HelmTemplate` class constructor is a dictionary
of values that represents the `values.yaml` that is used on the Helm command
line. This dictionary mirrors the YAML structure of the `values.yaml` file.

```ruby
describe 'some feature' do
  let(:default_values) do
    { 'certmanager-issuer' => { 'email' => 'test@example.com' } }
  end

  describe 'global.feature.enabled' do
    let(:values) do
      {
        'global' => {
          'feature' => {
            'enabled' => true
          }
        }
      }.merge(default_values)
    end

    ...
  end
end
```

The above snippet demonstrates a common pattern of setting a number of default
values that are common across multiple tests that are then merged into the
final values that are used in the `HelmTemplate` constructor for a specific
set of tests.

## Testing the results

The `HelmTemplate` object has a number of methods that assist with writing
RSpec tests. The following are a summary of the available methods.

- .exit_code()

This returns the exit code of the `helm template` command used to create the
YAML documents that instantiates the chart in the Kubernetes cluster. A
successful completion of the `helm template` will return an exit code of 0.

- .dig(key, ...)

Walk down the YAML document returned by the `HelmTemplate` instance and
return the value residing at the last key. If no value is found, then `nil`
is returned.

- .volumes(item)

Return an array of all the volumes for the specified deployment object.

- .find_volume(item, volume_name)

Return a dictionary of the specified volume from the specified deployment
object.

- .projected_volume_sources("KubernetesObj/name", "mount name")



- .stderr()

Return the STDERR output from the execution of `helm template` command.

- .values()

Return a dictionary of all values that were used in the execution of the
`helm template` command.
