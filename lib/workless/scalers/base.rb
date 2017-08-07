require 'delayed_job'

module Delayed
  module Workless
    module Scaler

      class Base
        def self.jobs
          if Rails.version >= '3.0.0'
            Delayed::Job.where(failed_at: nil)
          else
            Delayed::Job.all(conditions: { failed_at: nil })
          end
        end
      end

      module HerokuPlatform
        def client
          @client ||= ::PlatformAPI.connect_oauth(ENV['WORKLESS_OAUTH_TOKEN'])
        end
      end

    end
  end
end
