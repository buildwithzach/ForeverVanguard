SlashCommandUtil.CheckAddSlashCommand(SLASH_COMMAND.TARGET_MARKER, SLASH_COMMAND_CATEGORY.TARGET_MARKER, function(msg)
	local marker, target = SecureCmdOptionParse(msg);
	if ( not target ) then
		target = "target";
	end

	-- Prefixing with an "!" will prevent toggling the marker if it's already assigned.
	if ( marker and string.find(marker, "^!") ) then
		marker = tonumber(string.match(marker, "%d+"));

		if ( GetRaidTargetIndex(target) == marker ) then
			return;
		end
	-- Prefixing with a "~" will prevent setting the marker if the unit already has any marker.
	elseif ( marker and string.find(marker, "^~") ) then
		marker = tonumber(string.match(marker, "%d+"));

		if ( GetRaidTargetIndex(target) ~= nil ) then
			return;
		end
	else
		marker = tonumber(marker);
	end

	if ( marker ) then
		SetRaidTarget(target, tonumber(marker));	--Using /tm 0 will clear the target marker.
	end
end);
