def execute_command(command, hideOutput=false)
  lines_concantenated = ""
  IO.popen(command) do |output| 
    while line = output.gets do
      unless hideOutput
        puts line
      end
      lines_concantenated << line
    end
  end
  
  return lines_concantenated
end
