smartshop={
	user={},
	tmp={}
}

smartshop.showform=function(pos,player,re)
  if not pos or not player then
    return -- added to catch nil pos or player crash
  end
  local meta = minetest.get_meta(pos)
  local mode = meta:get_int("type")
  local inv = meta:get_inventory()
  local gui = ""
  local spos = pos.x .. "," .. pos.y .. "," .. pos.z
  local owner = meta:get_string("owner") == player:get_player_name()
  if re then owner=false end
  smartshop.user[player:get_player_name()]=pos
  if owner or minetest.check_player_privs(player:get_player_name(), {server=true}) and not re then
    gui=""
    .."size[8,10]"
    .."button_exit[6,0;1.7,1;customer;Customer]"
    .."label[0,0.2;Item:]"
    .."label[0,1.2;Price:]"
    .."list[nodemeta:" .. spos .. ";give1;2,0;1,1;]"
    .."list[nodemeta:" .. spos .. ";pay1;2,1;1,1;]"
    .."list[nodemeta:" .. spos .. ";give2;3,0;1,1;]"
    .."list[nodemeta:" .. spos .. ";pay2;3,1;1,1;]"
    .."list[nodemeta:" .. spos .. ";give3;4,0;1,1;]"
    .."list[nodemeta:" .. spos .. ";pay3;4,1;1,1;]"
    .."list[nodemeta:" .. spos .. ";give4;5,0;1,1;]"
    .."list[nodemeta:" .. spos .. ";pay4;5,1;1,1;]"
    if mode==1 then
      gui=gui.."list[nodemeta:" .. spos .. ";main;0,2;8,4;]"
    else
      gui=gui.."label[0.5,3;Unlimited Stock]"
    end
    gui=gui
    .."list[current_player;main;0,6.2;8,4;]"
    .."listring[nodemeta:" .. spos .. ";main]"
    .."listring[current_player;main]"
  else
    gui=""
    .."size[8,6]"
    .."list[current_player;main;0,2.2;8,4;]"
    .."label[0,0.2;Item:]"
    .."label[0,1.2;Price:]"
    .."list[nodemeta:" .. spos .. ";give1;2,0;1,1;]"
    .."item_image_button[2,1;1,1;".. inv:get_stack("pay1",1):get_name() ..
    ";buy1;\n\n\b\b\b\b\b" .. inv:get_stack("pay1",1):get_count() .."]"
    .."list[nodemeta:" .. spos .. ";give2;3,0;1,1;]"
    .."item_image_button[3,1;1,1;".. inv:get_stack("pay2",1):get_name() ..
    ";buy2;\n\n\b\b\b\b\b" .. inv:get_stack("pay2",1):get_count() .."]"
    .."list[nodemeta:" .. spos .. ";give3;4,0;1,1;]"
    .."item_image_button[4,1;1,1;".. inv:get_stack("pay3",1):get_name() ..
    ";buy3;\n\n\b\b\b\b\b" .. inv:get_stack("pay3",1):get_count() .."]"
    .."list[nodemeta:" .. spos .. ";give4;5,0;1,1;]"
    .."item_image_button[5,1;1,1;".. inv:get_stack("pay4",1):get_name() ..
    ";buy4;\n\n\b\b\b\b\b" .. inv:get_stack("pay4",1):get_count() .."]"
  end

    return minetest.show_formspec(player:get_player_name(), "smartshop.showform",gui)

end

minetest.register_on_player_receive_fields(function(player, form, pressed)
      if form == "smartshop.showform" then
        if pressed.customer then
          return smartshop.showform(smartshop.user[player:get_player_name()],player,true)
        elseif not pressed.quit then
          local n=1
          for i=1,4,1 do
            n=i
            if pressed["buy" .. i] then break end
          end
          local pos=smartshop.user[player:get_player_name()]
          -- check we have data to prevent server crash
          if not pos then return end
          local meta = minetest.get_meta(pos)
          local mode = meta:get_int("type")
          local inv = meta:get_inventory()
          local pinv = player:get_inventory()
          local pname = player:get_player_name()
          if pressed["buy" .. n] then
            local name = inv:get_stack("give" .. n,1):get_name()
            local stack=name .." ".. inv:get_stack("give" .. n,1):get_count()
            local pay=inv:get_stack("pay" .. n,1):get_name() .." ".. inv:get_stack("pay" .. n,1):get_count()
            if name~="" then
              if mode == 1 and inv:room_for_item("main", pay)==false then
				  minetest.chat_send_player(pname, "Error: The owners stock is full, cant receive, exchange aborted.")
				  return
			  end
              if mode == 1 and inv:contains_item("main", stack)==false then
				  minetest.chat_send_player(pname,
				  "Error: The owners stock has been traded.")
				  return
			  end
              if not pinv:contains_item("main", pay) then
				  minetest.chat_send_player(pname,
				  "Error: You dont have enough in your inventory to buy this, exchange aborted.")
				  return
			  end
              if not pinv:room_for_item("main", stack) then
				  minetest.chat_send_player(pname,
				  "Error: Your inventory is full, exchange aborted.")
				  return
			  end
              pinv:remove_item("main", pay)
              pinv:add_item("main", stack)
			  minetest.log("info", pname.." bought "..stack.. " costing "..pay)
              if mode == 1 then
                inv:remove_item("main", stack)
                inv:add_item("main", pay)
              end
            end
          end
        else
          smartshop.user[player:get_player_name()]=nil
        end
      end
end)

minetest.register_node("smartshop:shop", {
      description = "Smartshop",
      tiles = {"default_chest_top.png^[colorize:#ffffff77^default_obsidian_glass.png"},
      groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, not_in_creative_inventory=1},
      drawtype="nodebox",
      node_box = {type="fixed",fixed={-0.5,-0.5,-0.0,0.5,0.5,0.5}},
      paramtype2="facedir",
      paramtype = "light",
      sunlight_propagates = true,
      light_source = 10,
      after_place_node = function(pos, placer)
        local meta = minetest.get_meta(pos)
        meta:set_int("type",1)
        meta:set_string("owner", placer:get_player_name())
        meta:set_string("infotext", "Shop by: " .. placer:get_player_name())
        if minetest.check_player_privs(placer:get_player_name(), {creative=true}) then
          meta:set_int("type",2)
        end
      end,
      on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("state", 0)
        meta:get_inventory():set_size("main", 32)
        meta:get_inventory():set_size("give1", 1)
        meta:get_inventory():set_size("pay1", 1)
        meta:get_inventory():set_size("give2", 1)
        meta:get_inventory():set_size("pay2", 1)
        meta:get_inventory():set_size("give3", 1)
        meta:get_inventory():set_size("pay3", 1)
        meta:get_inventory():set_size("give4", 1)
        meta:get_inventory():set_size("pay4", 1)
      end,
      on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        smartshop.showform(pos,player)
      end,
      allow_metadata_inventory_put = function(pos, listname, index, stack, player)
          local name = player:get_player_name()
          local owner = minetest.get_meta(pos):get_string("owner")
          if owner == name or minetest.check_player_privs(name, {server=true}) then
			  if string.find(stack:get_name(), "admin") ~= nil or
			  string.find(stack:get_name(), "shop") ~= nil then return 0 end
              minetest.log("action", name.." puts "..stack:get_name()
              .." "..stack:get_count().." into "..owner.." shop @ "
			  ..minetest.pos_to_string(pos))
              return stack:get_count()
          end
          return 0
      end,
      allow_metadata_inventory_take = function(pos, listname, index, stack, player)
          local name = player:get_player_name()
          local owner = minetest.get_meta(pos):get_string("owner")
        if owner == name or minetest.check_player_privs(name, {server=true}) then
			if string.find(stack:get_name(), "admin") ~= nil then return 0 end
            minetest.log("action", name.." takes "..stack:get_name()
            .." "..stack:get_count().." from "..owner.." shop @ "
			..minetest.pos_to_string(pos))
            return stack:get_count()
        end
        return 0
      end,
      allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if minetest.get_meta(pos):get_string("owner") == player:get_player_name() or
		minetest.check_player_privs(player:get_player_name(), {server=true}) then
          return count
        end
        return 0
      end,
      can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if (meta:get_string("owner") == player:get_player_name()
          and inv:is_empty("main")
          and inv:is_empty("pay1")
          and inv:is_empty("pay2")
          and inv:is_empty("pay3")
          and inv:is_empty("pay4")
          and inv:is_empty("give1")
          and inv:is_empty("give2")
          and inv:is_empty("give3")
          and inv:is_empty("give4"))
        or meta:get_string("owner") == ""
        or minetest.check_player_privs(player:get_player_name(), {server=true}) then
          return true
        end
      end,
})

local old_entities = {"smartshop:item"}

for _,entity_name in ipairs(old_entities) do
    minetest.register_entity(":"..entity_name, {
        on_activate = function(self, staticdata)
            self.object:remove()
        end,
    })
end

minetest.register_lbm({
	name = "smartshop:replacer",
	nodenames = {"smartshop:shop"},
	action = function(pos, node)
		minetest.swap_node(pos, {name = "smartshop:shop", param2 = minetest.get_node(pos).param2})
	end,
})
