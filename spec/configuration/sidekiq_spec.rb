require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Sidekiq configuration' do
  let(:default_values) do
    {
      # provide required setting
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      # required to activate mailroom
      'gitlab' => {
        'sidekiq' => {
          'pods' => [
            { 'name' => 'pod-1', 'queues' => 'merge' },
            { 'name' => 'pod-2', 'negateQueues' => 'merge' },
          ]
        }
      }
    }
  end

  context 'when setting extraEnv' do
    def env(t, pod)
      t.dig("Deployment/test-sidekiq-#{pod}-v1", 'spec', 'template', 'spec', 'containers', 0, 'env')
    end

    context 'when the global value is set' do
      let(:global_values) do
        {
          'global' => {
            'extraEnv' => {
              'EXTRA_ENV_VAR_A' => 'global-a',
              'EXTRA_ENV_VAR_B' => 'global-b'
            }
          }
        }.deep_merge(default_values)
      end

      it 'sets those environment variables on each pod' do
        global_template = HelmTemplate.new(global_values)

        expect(global_template.exit_code).to eq(0)

        expect(env(global_template, 'pod-1'))
          .to include(
                { 'name' => 'EXTRA_ENV_VAR_A', 'value' => 'global-a' },
                { 'name' => 'EXTRA_ENV_VAR_B', 'value' => 'global-b' }
              )

        expect(env(global_template, 'pod-2'))
          .to include(
                { 'name' => 'EXTRA_ENV_VAR_A', 'value' => 'global-a' },
                { 'name' => 'EXTRA_ENV_VAR_B', 'value' => 'global-b' }
              )
      end

      context 'when the chart-level value is set' do
        let(:chart_values) do
          {
            'gitlab' => {
              'sidekiq' => {
                'extraEnv' => {
                  'EXTRA_ENV_VAR_A' => 'chart-a',
                  'EXTRA_ENV_VAR_C' => 'chart-c',
                  'EXTRA_ENV_VAR_D' => 'chart-d'
                }
              }
            }
          }
        end

        let(:chart_template) { HelmTemplate.new(global_values.deep_merge(chart_values)) }

        it 'sets those environment variables on each pod' do
          expect(chart_template.exit_code).to eq(0)

          expect(env(chart_template, 'pod-1'))
            .to include(
                  { 'name' => 'EXTRA_ENV_VAR_C', 'value' => 'chart-c' },
                  { 'name' => 'EXTRA_ENV_VAR_D', 'value' => 'chart-d' }
                )

          expect(env(chart_template, 'pod-2'))
            .to include(
                  { 'name' => 'EXTRA_ENV_VAR_C', 'value' => 'chart-c' },
                  { 'name' => 'EXTRA_ENV_VAR_D', 'value' => 'chart-d' }
                )
        end

        it 'overrides global values' do
          expect(env(chart_template, 'pod-1'))
            .to include('name' => 'EXTRA_ENV_VAR_A', 'value' => 'chart-a')

          expect(env(chart_template, 'pod-2'))
            .to include('name' => 'EXTRA_ENV_VAR_A', 'value' => 'chart-a')
        end

        context 'when the pod-level value is set' do
          let(:pod_values) do
            {
              'gitlab' => {
                'sidekiq' => {
                  'pods' => [
                    {
                      'name' => 'pod-1',
                      'queues' => 'merge',
                      'extraEnv' => {
                        'EXTRA_ENV_VAR_B' => 'pod-b',
                        'EXTRA_ENV_VAR_C' => 'pod-c',
                        'EXTRA_ENV_VAR_E' => 'pod-e'
                      }
                    },
                    {
                      'name' => 'pod-2',
                      'negateQueues' => 'merge',
                      'extraEnv' => {
                        'EXTRA_ENV_VAR_B' => 'pod-b',
                        'EXTRA_ENV_VAR_C' => 'pod-c',
                        'EXTRA_ENV_VAR_F' => 'pod-f'
                      }
                    },
                  ]
                }
              }
            }
          end

          let(:pod_template) do
            HelmTemplate.new(global_values.deep_merge(chart_values).deep_merge(pod_values))
          end

          it 'sets those environment variables on the relevant pods' do
            expect(pod_template.exit_code).to eq(0)

            expect(env(pod_template, 'pod-1'))
              .to include('name' => 'EXTRA_ENV_VAR_E', 'value' => 'pod-e')

            expect(env(pod_template, 'pod-2'))
              .to include('name' => 'EXTRA_ENV_VAR_F', 'value' => 'pod-f')
          end

          it 'overrides global values' do
            expect(env(pod_template, 'pod-1'))
              .to include('name' => 'EXTRA_ENV_VAR_B', 'value' => 'pod-b')

            expect(env(pod_template, 'pod-2'))
              .to include('name' => 'EXTRA_ENV_VAR_B', 'value' => 'pod-b')
          end

          it 'overrides chart-level values' do
            expect(env(pod_template, 'pod-1'))
              .to include('name' => 'EXTRA_ENV_VAR_C', 'value' => 'pod-c')

            expect(env(pod_template, 'pod-2'))
              .to include('name' => 'EXTRA_ENV_VAR_C', 'value' => 'pod-c')
          end
        end
      end
    end
  end
end
