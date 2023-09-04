# frozen_string_literal: true

require 'pp'
require_relative '../command'
require 'aws-sdk-ecs'
require 'tty-prompt'
require 'pastel'
require 'ecsecute/errors'
module Ecsecute
  module Commands
    class Exec < Ecsecute::Command
      attr_reader :region

      def initialize(i, options)
        @pastel = Pastel.new
        @region = options['region'] || 'us-east-1'
        @client = Aws::ECS::Client.new(
          region: region,
          credentials: Aws::SharedCredentials.new
        )
        @command = i
        @options = { 'interactive' => true }.merge(options)
        @interactive = @options['interactive'] || true
      end

      def interactive
        @interactive ? '--interactive' : ''
      end

      def tasks
        @client.list_tasks(cluster: cluster).task_arns.map { |task| task.gsub(%r{.*/}, '') }
      end

      def task
        return @task unless @task.nil?
        return tasks.first if tasks.count == 1

        prompt = TTY::Prompt.new(symbol: { marker: '>' })
        @task = prompt.select('Select task', tasks)
      end

      def containers
        @containers ||= @client.describe_tasks(cluster: cluster,
                                               tasks: [task]) \
                                               .tasks.map(&:containers) \
                                               .flatten.map(&:name)
      end

      def container
        return @container unless @container.nil?
        return containers.first if containers.count == 1

        prompt = TTY::Prompt.new(symbol: { marker: '>' })
        @container = prompt.select('Select container', containers)
      end

      def clusters
        return @clusters unless @clusters.nil?

        raw_clusters = @client.list_clusters.cluster_arns
        active_clusters = @client.describe_clusters(clusters: raw_clusters).clusters.select do |cluster|
          cluster.status == 'ACTIVE'
        end
        matching_clusters = active_clusters.map(&:cluster_name).select do |cluster|
          cluster.match(/#{@options["cluster"]}/)
        end
        @clusters = matching_clusters.select do |cluster|
          @client.describe_clusters(clusters: [cluster]).clusters.first.status == 'ACTIVE'
        end
      end

      def cluster
        return @cluster unless @cluster.nil?
        return clusters.first if clusters.count == 1

        prompt = TTY::Prompt.new(symbol: { marker: '>' })
        @cluster = prompt.select('Select cluster', clusters)
      end

      def execute(input: $stdin, output: $stdout)
        validate!
        # TODO: Run ECS command via API rather than shelling out.
        output.puts "Executing " \
          + "#{@pastel.green(@command)} " \
          + "on cluster: #{@pastel.green(cluster)}, " \
          + "task: #{@pastel.green(task)}, " \
          + "container: #{@pastel.green(container)}"
        Kernel.exec "aws ecs execute-command  --region us-east-1 --cluster #{cluster} --task #{task}  --container #{container} --command #{@command} #{interactive}"
      end

      def validate!
        raise EcsecuteErrors::ClusterNotFound if clusters.empty?
        raise EcsecuteErrors::TaskNotFound if tasks.empty?
        raise EcsecuteErrors::ContainerNotFound if containers.empty?
      end
      
    end
  end
end
