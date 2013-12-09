class Rake::Task
  def overwrite(&block)
    @prerequisites.clear
    @actions.clear
    enhance(&block)
  end
end
