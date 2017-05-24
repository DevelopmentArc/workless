require 'spec_helper'

describe Delayed::Workless::Scaler::HerokuCedar do
  before(:each) do
    ENV['WORKLESS_MAX_WORKERS'] = ENV['WORKLESS_MIN_WORKERS'] = ENV['WORKLESS_WORKERS_RATIO'] = nil
  end

  context 'workers' do
    before do
      Delayed::Workless::Scaler::HerokuCedar.stub(:jobs).and_return(NumWorkers.new(10))
    end

    let :list_results do
      [
        {
          "app" => {
            "id" => "123123123-1233-45f5-1234-123123123123",
            "name" => "production-example"
          },
          "command" => "bundle exec rake jobs:work",
          "created_at" => "2013-01-18T22:48:47Z",
          "id" => "222233334445555",
          "type" => "worker",
          "quantity" => 3,
          "size" => "Standard-2X",
          "updated_at" => "2017-05-24T18:27:57Z"
        },
        {
          "app" => {
            "id" => "123123123-1233-45f5-1234-123123123123",
            "name" => "production-example"
          },
          "command" => "bundle exec rake jobs:work",
          "created_at" => "2013-01-18T22:48:47Z",
          "id" => "222233334445555",
          "type" => "web",
          "quantity" => 2,
          "size" => "Standard-1X",
          "updated_at" => "2017-05-24T18:27:57Z"
        }
      ]
    end

    let :formation_stub do
      double(:formation)
    end

    it 'calls formation' do
      Delayed::Workless::Scaler::HerokuCedar.stub_chain(:client, :formation).and_return(formation_stub)
      formation_stub.should_receive(:list).once.with(ENV['APP_NAME']).and_return(list_results)
      Delayed::Workless::Scaler::HerokuCedar.workers
    end

    context 'formation data' do
      before do
        Delayed::Workless::Scaler::HerokuCedar.stub_chain(:client, :formation, :list).and_return(list_results)
      end

      it 'parses workers' do
        expect(Delayed::Workless::Scaler::HerokuCedar.workers).to eq(3)
      end
    end

    context 'scales workers' do
      it 'scales based on the passed quantity' do
        Delayed::Workless::Scaler::HerokuCedar.stub_chain(:client, :formation).and_return(formation_stub)
        formation_stub.should_receive(:update).once.with(ENV['APP_NAME'], 'worker', {"quantity" => 2})
        Delayed::Workless::Scaler::HerokuCedar.scale_workers(2)
      end

    end
  end

  context 'with jobs' do

    before do
      Delayed::Workless::Scaler::HerokuCedar.stub(:jobs).and_return(NumWorkers.new(10))
    end

    context 'without workers' do

      before do
        Delayed::Workless::Scaler::HerokuCedar.stub(:workers).and_return(0)
      end

      it 'should set the workers to 1' do
        Delayed::Workless::Scaler::HerokuCedar.should_receive(:scale_workers).once.with(1)
        Delayed::Workless::Scaler::HerokuCedar.up
      end

    end

    context 'with workers' do

      before do
        Delayed::Workless::Scaler::HerokuCedar.stub(:workers).and_return(10)
      end

      it 'should not set anything' do
        Delayed::Workless::Scaler::HerokuCedar.should_not_receive(:scale_workers)
        Delayed::Workless::Scaler::HerokuCedar.up
      end

    end

  end

  context 'with no jobs' do

    before do
      Delayed::Workless::Scaler::HerokuCedar.stub(:jobs).and_return(NumWorkers.new(0))
    end

    context 'without workers' do

      before do
        Delayed::Workless::Scaler::HerokuCedar.should_receive(:workers).and_return(0)
      end

      it 'should not set anything' do
        Delayed::Workless::Scaler::HerokuCedar.should_not_receive(:scale_workers)
        Delayed::Workless::Scaler::HerokuCedar.down
      end

    end

    context 'with workers' do

      before do
        Delayed::Workless::Scaler::HerokuCedar.stub(:workers).and_return(NumWorkers.new(10))
      end

      it 'should set the workers to 0' do
        Delayed::Workless::Scaler::HerokuCedar.should_receive(:scale_workers).once.with(0)
        Delayed::Workless::Scaler::HerokuCedar.down
      end

    end

  end

end
