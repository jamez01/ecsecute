# frozen_string_literal: true

require 'pp'
require_relative '../command'
require 'aws-sdk-ecs'
require 'ecsecute/errors'
module Ecsecute
  module Commands
    class Exec < Ecsecute::Command
      attr_reader :region

      def initialize(i, options)
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
        return_matching(@client.list_tasks(cluster: cluster).task_arns.map { |task| task.gsub(%r{.*/}, '') }, @options["task"])
      end

      def task
        return @task unless @task.nil?
        return tasks.first if tasks.count == 1

        @task = prompt.select('Select task', tasks)
      end

      def containers
        all_containers ||= @client.describe_tasks(cluster: cluster,
                                               tasks: [task]) \
                                               .tasks.map(&:containers) \
                                               .flatten.map(&:name)
        @containers = return_matching(all_containers, @options["container"])
      end

      def container
        return @container unless @container.nil?
        return containers.first if containers.count == 1

        @container = prompt.select('Select container', containers)
      end

      def clusters
        return @clusters unless @clusters.nil?

        raw_clusters = @client.list_clusters.cluster_arns
        active_clusters = @client.describe_clusters(clusters: raw_clusters).clusters.select do |cluster|
          cluster.status == 'ACTIVE'
        end
        @clusters = return_matching(active_clusters.map(&:cluster_name), @options["cluster"])
      end

      def cluster
        return @cluster unless @cluster.nil?
        return clusters.first if clusters.count == 1
        
        @cluster = prompt.select('Select cluster', clusters)
      end

      def execute(input: $stdin, output: $stdout)
        validate!
        # TODO: Run ECS command via API rather than shelling out.
        output.puts "Executing " \
          + "#{pastel.green(@command)} " \
          + "on cluster: #{@pastel.green(cluster)}, " \
          + "task: #{pastel.green(task)}, " \
          + "container: #{pastel.green(container)}"
        Kernel.exec "aws ecs execute-command  --region us-east-1 --cluster #{cluster} --task #{task}  --container #{container} --command #{@command} #{interactive}"
      end

      def validate!
        raise EcsecuteErrors::ClusterNotFound if clusters.empty?
        raise EcsecuteErrors::TaskNotFound if tasks.empty?
        raise EcsecuteErrors::ContainerNotFound if containers.empty?
      end
      private
      def return_matching(list, keyword)
        list.select { |item| item.match(/#{keyword}/i) }
      end
    end
  end
end
