class PumaStatsLogger

  def self.run
    sleep 10 # wait for puma to boot


    metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
    instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )

    ec2 = Aws::EC2.new()
    puts "ec2: #{ec2.methods}"
    instance = ec2.instances[instance_id]
    puts "instance: #{instance}"
    puts "instance.tags: #{instance.try(:tags)}"

    Thread.new do
      loop do
        begin
          stats = JSON.parse Puma.stats, symbolize_names: true
          sum_max_threads = 0
          sum_pool_capacity = 0
          sum_backlog = 0
          sum_running = 0
          stats[:worker_status].each do |worker|

            Rails.logger.info "puma worker threads - pid: #{worker[:pid]} #{worker[:last_status]}"
            sum_max_threads = worker[:last_status]
            sum_pool_capacity = worker[:last_status]
            sum_backlog = worker[:last_status]
            sum_running = worker[:last_status]
          end
          cw = Aws::CloudWatch::Client.new(region: 'us-east-2')
          cw.put_metric_data({
            namespace: "PumaServer",
            metric_data: [
              {
                metric_name: "Backlog",
                dimensions: [
                  {
                    name: "AutoScalingGroupName",
                    value: "awseb-e-vhty3ru5fj-stack-AWSEBAutoScalingGroup-686KS6C477I4"
                  }
                ],
                value: sum_backlog,
                unit: "Count"
              },
              {
                metric_name: "Running",
                dimensions: [
                  {
                    name: "AutoScalingGroupName",
                    value: "awseb-e-vhty3ru5fj-stack-AWSEBAutoScalingGroup-686KS6C477I4"
                  }
                ],
                value: sum_running,
                unit: "Count"
              },
              {
                metric_name: "Thread Utilization",
                dimensions: [
                  {
                    name: "AutoScalingGroupName",
                    value: "awseb-e-vhty3ru5fj-stack-AWSEBAutoScalingGroup-686KS6C477I4"
                  }
                ],
                value: ((sum_max_threads - sum_pool_capacity) / sum_max_threads),
                unit: "Percent"
              }
            ]
          })
          Rails.logger.flush
        rescue => e
          Rollbar.error e
        end

        sleep 60
      end
    end
  end

end