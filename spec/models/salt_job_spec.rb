require "rails_helper"

describe SaltJob do
  it { is_expected.to validate_uniqueness_of(:jid) }

  context "when a job is completed" do
    it "defaults to falsey" do
      expect(described_class.new).not_to be_completed
    end

    it "can be set by an action" do
      job = described_class.new
      job.complete!
      expect(job).to be_completed
    end
  end

  context "when storing the job return code" do
    it "defaults to success" do
      job = described_class.new
      job.complete!
      expect(job.retcode).to eq(0)
    end

    it "can be set for success during completion" do
      job = described_class.new
      job.complete!(0)
      expect(job.retcode).to eq(0)
    end

    it "can be set for failure" do
      job = described_class.new
      job.complete!(1)
      expect(job.retcode).to eq(1)
    end

    it "informs success" do
      job = described_class.new
      job.complete!(0)
      expect(job).to be_succeeded
    end

    it "informs against failure" do
      job = described_class.new
      job.complete!(0)
      expect(job).not_to be_failed
    end

    it "informs failure" do
      job = described_class.new
      job.complete!(1)
      expect(job).to be_failed
    end

    it "informs against success" do
      job = described_class.new
      job.complete!(1)
      expect(job).not_to be_succeeded
    end
  end

  context "when storing error traces" do
    let(:master_trace) { FFaker::Lorem.paragraph }
    let(:minion_trace) { FFaker::Lorem.paragraph }

    it "is empty on success" do
      job = described_class.new
      job.complete!
      expect(job.master_trace).to be_nil
      expect(job.minion_trace).to be_nil
    end

    it "set when the job is completed" do
      job = described_class.new
      job.complete!(1, master_trace: master_trace, minion_trace: minion_trace)
      expect(job.master_trace).to eq(master_trace)
      expect(job.minion_trace).to eq(minion_trace)
    end

    context "when evaluating the error trace" do
      let(:jid) { Time.current.strftime("%Y%m%d%H%M%S%6N") }
      let(:log_reference_msg) do
        "Please check `/var/log/salt/minion` for details."
      end
      let(:upstream_error_msg) do
        "InstanceLimitExceeded: "\
        "Your quota allows for 0 more running instance(s). "\
        "You requested at least 1"
      end

      it "points at the logs with only a master trace" do
        job = described_class.new(jid: jid)
        job.complete!(1, master_trace: master_trace)
        expect(job.errors[:base]).to include(log_reference_msg)
      end

      # it "provides an upstream error with a minion trace" do
      #   job = described_class.new(jid: jid)
      #   job.complete!(1, minion_trace: minion_trace)
      #   expect(job.errors[:base]).to include(upstream_error_msg)
      # end
    end
  end
end
