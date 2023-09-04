module EcsecuteErrors
  class ClusterNotFound < StandardError
    def initialize(msg = "No Cluster(s) found")
      super
    end
  end

  class ContainerNotFound < StandardError
    def initialize(msg = "No Container(s) found")
      super
    end
  end

  class TaskNotFound < StandardError
    def initialize(msg = "No Task(s) found")
      super
    end
  end
end