require "spec_helper"

describe Dotenv::Substitutions::Variable do
  context "given an escaped $" do
    it "returns the literal value" do
      expect(described_class.("\\$FOO", env("FOO=SBALL"))).to eq("$FOO")
      expect(described_class.("\\${BAR}", env("BAR=LEYCORN"))).to eq("${BAR}")
    end
  end

  context "given an unescaped $" do
    context "with an environment file containing a corresponding definition" do
      it "expands to the defined value" do
        expect(described_class.("$THIS", env("THIS=TLE"))).to eq("TLE")
        expect(described_class.("${THAT}", env("THAT=CHED"))).to eq("CHED")
      end
    end

    context "without a corresponding definition in the environment file" do
      let(:empty_env) { env("") }

      before do
        ENV["IRON"] = "MENT"
        ENV["IOUS"] = "NESS"
      end

      it "expands to the corresponding value from ENV (if available)" do
        expect(described_class.("$IRON", empty_env)).to eq("MENT")
        expect(described_class.("${IOUS}", empty_env)).to eq("NESS")
        expect(described_class.("$NADA", empty_env)).to be_empty
      end
    end

    context "when variable is surrounded with ${}" do
      context "given the parameter-expansion operator" do
        context "${#VAR}" do
          it "returns the length of the string" do
            expect(described_class.("${#LONG}", env("LONG=ITUDE"))).to eq("5")
          end
        end

        context "${!VAR}" do
          it "returns an indirect expansion" do
            expect(described_class.("${!INDI}", env("INDI=RECT\nRECT=OR"))).to eq("OR")
            expect(described_class.("${!RAB,,}", env("RAB=BIT\nBIT=HOLE"))).to eq("hole")
          end
        end

        context "${VAR%%GLOB}" do
          it "removes the longest right-anchored match" do
            expect(described_class.("${GONE%%home*}", env("GONE='me a home where the buffalo roam'"))).to eq("me a ")
          end
        end

        context "${VAR%GLOB}" do
          it "removes the shortest right-anchored match" do
            expect(described_class.("${I%wanna*}", env("I='wanna wanna shock treatment'"))).to eq("wanna ")
          end
        end

        context "${VAR##GLOB}" do
          it "removes the longest left-anchored match" do
          end
        end

        context "${VAR#GLOB}" do
          it "removes the shortest left-anchored match" do
          end
        end

        context ":N:N" do
          it "returns a substring slice" do
            expect(described_class.("${STORE:2:4}", env("STORE=HOUSES"))).to eq("USES")
          end

        end

        context "%%" do

        end

        context "##" do

        end

        context "/" do
        end

        context "//" do

        end

        context "-" do

        end

        context ":-" do
        end

        context "+" do
        end

        context ":+" do
        end
      end
    end
  end

  require "tempfile"
  def env(text)
    file = Tempfile.new("dotenv")
    file.write text
    file.close
    env = Dotenv::Environment.new(file.path)
    file.unlink
    env
  end
end
