module Delayed
  module Workless
    module Scaler

      autoload :HerokuCedar, 'workless/scalers/heroku_cedar'
      autoload :Local,       'workless/scalers/local'
      autoload :Null,        'workless/scalers/null'

      def self.included(base)
        base.send :extend, ClassMethods
        if base.to_s.match?(/ActiveRecord/)
          base.class_eval do
            after_commit :scaler_down, on: :update, if: proc { |r| !r.failed_at.nil? }
            after_commit :scaler_down, on: :destroy, if: proc { |r| r.destroyed? or !r.failed_at.nil? }
            after_commit :scaler_up, on: :create
          end
        elsif base.to_s.match?(/Sequel/)
          base.send(:define_method, 'after_destroy') do
            super
            self.class.scaler.down
          end
          base.send(:define_method, 'after_create') do
            super
            self.class.scaler.up
          end
          base.send(:define_method, 'after_update') do
            super
            self.class.scaler.down
          end
        else
          base.class_eval do
            after_destroy :scaler_down
            after_create :scaler_up
            after_update :scaler_down, unless: proc { |r| r.failed_at.nil? }
          end
        end
      end

      def scaler_up
        self.class.scaler.up
      end

      def scaler_down
        self.class.scaler.down
      end

      module ClassMethods
        def scaler
          @scaler ||= if ENV.include?('HEROKU_API_KEY')
            Scaler::HerokuCedar
          else
            Scaler::Local
          end
        end

        def scaler=(scaler)
          @scaler = "Delayed::Workless::Scaler::#{scaler.to_s.camelize}".constantize
        end
      end

    end

  end
end
