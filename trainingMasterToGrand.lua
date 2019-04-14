quest trainingSoulStones begin
	state start begin
		function isQuestAvailable(isItem)
			if not pc.can_warp() then say("Trebuie sa astepti 10 secunde pentru a continua!") return false; end
			if isItem then if (pc.count_item(item.get_vnum()) == 0) then say("Nu ai obiectul in inventar!") return false; end end
			if pc.is_trade0() then syschat("Inchide fereastra de trade!") return false; end
			if pc.is_busy0() then syschat("Inchide celelalte ferestre!") return false; end
			return true;
		end
		
		function insertSkillData()
			local playerJob = pc.get_job();
			local playerGroup = pc.get_skill_group();
			local selectedTable = playerSkillData[playerJob + 1][playerGroup];
			
			local minimumSkillLevel = 30;
			local maximumSkillLevel = 40;
			
			local selectSkillTable = {["skillData"] = {}, ["skillIndex"] = {}};
			for index in selectedTable["skillVnums"] do
				local skillLevel = pc.get_skill_level(selectedTable["skillVnums"][index]);
				
				if ((skillLevel >= minimumSkillLevel) and (skillLevel < maximumSkillLevel)) then
					local stringValue = trainingSoulStones.returnSkillString(index);
					table.insert(selectSkillTable["skillData"], string.format("%s", stringValue));
					table.insert(selectSkillTable["skillIndex"], index);
				end
			end table.insert(selectSkillTable["skillData"], "Renunta");
			return selectSkillTable;
		end
		
		function returnSkillString(index)
			local playerJob = pc.get_job();
			local playerGroup = pc.get_skill_group();
			local selectedTable = playerSkillData[playerJob + 1][playerGroup];
			
			local skillLevel = pc.get_skill_level(selectedTable["skillVnums"][index]);
			local skillAttribute = "G";
			local skillStatus = skillLevel + 2 - 30;
			
			if (skillStatus > 10) then skillAttribute = "P"; skillStatus = 1 end
			return string.format("%s - G%d > %s%d", selectedTable["skillNames"][index], skillLevel + 1 - 30, skillAttribute, skillStatus);
		end
		
		when 50513.use begin
			if (pc.get_skill_group() == 0) then
				say(string.format("Nu poti folosi %s fara ati alege competentele", item_name(item.get_vnum())))
				return;
			end
			
			if (get_time() < pc.getqf("next_time")) then
				if pc.is_skill_book_no_delay() then
					pc.remove_skill_book_no_delay();
				else
					say(string.format("Mai ai de asteptat %s.", get_time_format(pc.getqf("next_time") - get_time())))
					return;
				end
			end
			
			local playerJob = pc.get_job();
			local playerGroup = pc.get_skill_group();
			local selectedTable = playerSkillData[playerJob + 1][playerGroup];
			
			local skillArray = trainingSoulStones.insertSkillData();
			if (table.getn(skillArray["skillData"]) < 2) then
				say("Nu ai aptitudini de imbunatatit.")
				return;
			end
			
			local selectChoice = select_table(skillArray["skillData"]);
			if (selectChoice == table.getn(skillArray["skillData"])) then return; end
			if (isQuestAvailable.isQuestAvailable(true)) then
				local skillLevel = pc.get_skill_level(selectedTable["skillVnums"][skillArray["skillIndex"][selectChoice]]);
				
				local stringValue = trainingSoulStones.returnSkillString(skillArray["skillIndex"][selectChoice]);
				say(string.format("Esti sigur ca doresti sa imbunatatesti[ENTER]%s?", stringValue))
				
				if (select("Yes, sir", "No, thanks") == 1) then
					if (isQuestAvailable.isQuestAvailable(true)) then
						local currentAligment = pc.get_real_alignment();
						local requireAligment = 1000+500*(skillLevel-30)
						
						if currentAligment<-19000+requireAligment then
							say("Nu ai destule puncte la grad!")
							return
						end
						
						if pc.learn_grand_master_skill(selectedTable["skillVnums"][skillArray["skillIndex"][selectChoice]]) then
							pc.change_alignment(-requireAligment);
							
							if (40 == pc.get_skill_level(selectedTable["skillVnums"][skillArray["skillIndex"][selectChoice]])) then
								syschat(string.format("%s a devenit PERFECT.", selectedTable["skillNames"][skillArray["skillIndex"][selectChoice]]))
							else
								syschat(string.format("Ai urcat %s catre G%d!", selectedTable["skillNames"][skillArray["skillIndex"][selectChoice]], skillLevel-30+1+1))
							end
							
							syschat("Succes!")
							syschat(string.format("Puncte de grad luate: %d ", requireAligment))
						else
							syschat(string.format("%s - A esuat", item_name(item.get_vnum())))
							pc.change_alignment(-number(requireAligment/3, requireAligment/2));
						end
						pc.setqf("next_time", get_time() + 60 * 60 * 8); pc.remove_item(item.get_vnum(), 1);
					end
				end
			end
		end
	end
end