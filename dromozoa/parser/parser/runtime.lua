return [=[
return function (self, terminal_nodes)
  local max_state = self.max_state
  local max_terminal_symbol = self.max_terminal_symbol
  local actions = self.actions
  local gotos = self.gotos
  local heads = self.heads
  local sizes = self.sizes
  local reduce_to_semantic_action = self.reduce_to_semantic_action
  local reduce_to_attribute_actions = self.reduce_to_attribute_actions
  local stack = { 1 } -- start state
  local nodes = {}

  for i = 1, #terminal_nodes do
    local node = terminal_nodes[i]
    local symbol = node[0]
    while true do
      local n1 = #stack
      local n2 = #nodes
      local state = stack[n1]

      local action
      if symbol <= max_terminal_symbol then
        action = actions[state][symbol]
      else
        action = gotos[state][symbol - max_terminal_symbol]
      end

      if action then
        if action <= max_state then -- shift
          stack[n1 + 1] = action
          nodes[n2 + 1] = node
          break
        else
          local head = heads[action]
          if head then -- reduce
            local n = sizes[action]
            for j = n1 - n + 1, n1 do
              stack[j] = nil
            end

            local reduced_nodes = {}
            for j = n2 - n + 1, n2 do
              reduced_nodes[#reduced_nodes + 1] = nodes[j]
              nodes[j] = nil
            end

            local node
            local semantic_action = reduce_to_semantic_action[action]
            if semantic_action then
              local code = semantic_action[1]
              if code == 1 then -- collapse node
                local index = semantic_action[2]
                local indices = semantic_action[3]
                if index > 0 then
                  node = reduced_nodes[index]
                else
                  node = { [0] = -index }
                end
                for j = 1, #indices do
                  local index = indices[j]
                  if index > 0 then
                    node[#node + 1] = reduced_nodes[index]
                  else
                    node[j] = { [0] = -index }
                  end
                end
              elseif code == 2 then -- create node
                local indices = semantic_action[2]
                node = { [0] = head }
                for j = 1, #indices do
                  local index = indices[j]
                  if index > 0 then
                    node[j] = reduced_nodes[index]
                  else
                    node[j] = { [0] = -index }
                  end
                end
              end
            else
              node = { [0] = head }
              for j = 1, n do
                node[j] = reduced_nodes[j]
              end
            end

            local attribute_actions = reduce_to_attribute_actions[action]
            if attribute_actions then
              for i = 1, #attribute_actions do
                local attribute_action = attribute_actions[i]
                local code = attribute_action[1]
                if code == 1 then -- set attribute
                  node[attribute_action[2]] = attribute_action[3]
                elseif code == 2 then -- set child attribute
                  reduced_nodes[attribute_action[2]][attribute_action[3]] = attribute_action[4]
                end
              end
            end

            local n1 = #stack
            local n2 = #nodes
            local state = stack[n1]
            stack[n1 + 1] = gotos[state][head - max_terminal_symbol]
            nodes[n2 + 1] = node
          else -- accept
            stack[n1] = nil
            local accepted_node = nodes[n2]
            nodes[n2] = nil
            return accepted_node
          end
        end
      else
        return nil, "parser error", node.i
      end
    end
  end
end
]=]
