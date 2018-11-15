require 'rugged'

module GitFlow
  # The module where all the git related stuff goes in
  module GitMethods

    # This sets up the git half of a feature
    # 
    # @git_base: The baseline Rugged::Commit to diff against
    # @git_branch: Rugged::Branch of origin/<branch> 
    #
    # @param [String] branch_name The branch-name as string
    # @param [Rugged::Repository] repo
    def _create_git(branch_name, repo)
      @git_branch = create_local_branch(branch_name, repo)
      raise GitFlow::Error, "Unable to find feature branch: #{branch_name}" if @git_branch.nil?()
      @git_base   = merge_base(repo, branch_name)
      raise GitFlow::Error, "Unable to find base branch: #{@base}"        if @git_base.nil?()
    end

    # Creates a local branch tracking upstream if it does not already exist
    # @param [String] branch_name feature-branch name
    # @param [Rugged::Repository] repo 
    def create_local_branch(branch_name, repo)
      local_branch  = repo.branches[branch_name]
      return local_branch unless local_branch.nil?
            
      $logger.debug("Creating local branch: #{branch_name}")
      rbranch = "#{@remote_name}/#{branch_name}"
      raise GitFlow::Error, "Unable to find remote branch #{rbranch}" if repo.branches[rbranch].nil?()

      repo.create_branch(branch_name, rbranch)
    end

    # Find the merge_base commit
    # https://git-scm.com/docs/git-merge-base
    #
    # @param [Rugged::Repository] repo 
    # @param [String] oid1 
    # @param [String] oid2 defaults to @base => 'master'
    # @return [Rugged::Commit, nil] 
    def merge_base(repo, oid1, oid2=nil)
     oid2 = oid2 || @base || 'master'

     base = repo.merge_base(oid1, oid2)
     base.nil?() ? nil : repo.lookup(base)
    end
  
    # Get a list of changed files 
    #
    # @param [Rugged::Commit, Rugged::Branch] base defaults to @git_base
    # @param [Rugged::Commit, Rugged::Branch] base defaults to @git_branch
    # @return [Array<String>] A list of changed paths
    def get_diff_paths(base=nil, head=nil)
      base = base || @git_base
      head = head || @git_branch

      raise GitFlow::Error, "Diff failed: base is nil"   if base.nil?
      raise GitFlow::Error, "Diff failed: branch is nil" if head.nil?

      paths = []
      base_commit = base.kind_of?(Rugged::Reference) ? base.target : base
      head_commit = head.kind_of?(Rugged::Reference) ? head.target : head

      diff = base_commit.diff(head_commit)
      diff.each_delta do |delta|
        next if delta.deleted?()
        paths << delta.new_file[:path]
      end
      paths
    end

    def self.get_remote_branches(prefix=nil, remote=nil, repo=nil)
      prefixes    = prefix || @prefix || ['feature', 'fix', 'master']
      remote_name = remote || @remote || 'origin'
      repo        = @git_repo || $git_repo
      repo.branches.each(:remote).select{|remote_branch| prefixes.any?{|prefix| remote_branch.name.match("#{remote_name}/#{prefix}")  } }
    end

  end
end
