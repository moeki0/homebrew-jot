class Jot < Formula
  desc "Channel-based jot/notes server with Claude Code integration"
  homepage "https://github.com/moeki0/jot"
  url "https://github.com/moeki0/jot/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "a471797b652001b7fd02ee5776b17eb127283043ad0da08db090d3db440c5723"
  license "MIT"

  resource "bun" do
    on_arm do
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.12/bun-darwin-aarch64.zip"
      sha256 "6c4bb87dd013ed1a8d6a16e357a3d094959fd5530b4d7061f7f3680c3c7cea1c"
    end
    on_intel do
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.12/bun-darwin-x64.zip"
      sha256 :no_check
    end
  end

  def install
    resource("bun").stage do
      bun_bin = Dir["bun-*/bun"].first || "bun"
      buildpath.install bun_bin => "bun"
    end
    chmod 0755, buildpath/"bun"
    bun = (buildpath/"bun").to_s

    system bun, "install", "--frozen-lockfile"
    system bun, "run", "build"

    libexec.install "src", "public", "package.json", "bun.lock", "node_modules"
    libexec.install "bun"

    (bin/"jot").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bun" "#{libexec}/src/cli.ts" "$@"
    SH
    chmod 0755, bin/"jot"
  end

  def caveats
    <<~EOS
      Start the jot server:
        jot serve

      Then open http://localhost:7878 in your browser.

      Register Claude Code hooks (optional):
        jot claude hook <stop|user-prompt|tool|notify|session-start>
    EOS
  end

  test do
    assert_match "jot", shell_output("#{bin}/jot bogus 2>&1", 2)
  end
end
