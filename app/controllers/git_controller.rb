require 'rugged'

class GitController < ApplicationController
  def index
    repo = Rugged::Repository.new('/Users/deity/programming/graphics_hw')
    
    @blame = Rugged::Blame.new(repo, "Animation/Animation/main.cpp")


  end
end
