fchat.sql = {}
fchat.sql.remote = {}

local queue = {}
local firstTime = true
local tableName = "fchat_remote"

----------------------------------------------------------------------	
-- Purpose:
--		Initializes the database object.
----------------------------------------------------------------------

function fchat.sql.Initialize(callback_success, callback_failed)
	local exists = sql.TableExists(tableName)
	
	if (!exists) then
		sql.Query("CREATE TABLE " .. tableName .. "(address TEXT DEFAULT \"\" NOT NULL UNIQUE, port INTEGER DEFAULT 3306 NOT NULL UNIQUE, user TEXT DEFAULT \"\" NOT NULL UNIQUE, password TEXT DEFAULT \"\" NOT NULL UNIQUE, database TEXT DEFAULT \"fchat\" NOT NULL UNIQUE)")
	else
		-- Compatibility operations for sql tables are done here.
		if (!FCHAT_VERSION_PREVIOUS or FCHAT_VERSION_PREVIOUS != FCHAT_VERSION) then
			
			if (FCHAT_VERSION_PREVIOUS) then
			
				-- Insert the "database" field if we're upgrading from version 2.2.0
				if (FCHAT_VERSION_PREVIOUS == 220) then
					sql.Query("ALTER TABLE " .. tableName .. " ADD database TEXT DEFAULT \"fchat\" NOT NULL")
					sql.Query("UPDATE " .. tableName .. " SET database = 'fchat'")
				end
			end
		end
	end
	
	local data = sql.Query("SELECT address, port, user, password, database FROM " .. tableName)
	
	if (data) then
		data = data[1]
		
		fchat.sql.remote = data
		
		if (!mysqloo) then
			local success, message = pcall(require, "mysqloo")
			
			if (!success) then
				ErrorNoHalt("[fchat] Could not find the mysqloo module: " .. tostring(message) .. "\n")
			end
		end
		
		if (mysqloo) then
			if (fchat.sql.remote.object) then fchat.sql.remote.object = nil end
			
			local database = mysqloo.connect(data.address, data.user, data.password, data.database or "fchat", tonumber(data.port))

			ServerLog("[fchat] Connecting to database...\n")
			
			function database:onConnected()
				ServerLog("[fchat] Connection to database established.\n")
				
				fchat.sql.remote.object = self
				
				hook.Call("fchat.DatabaseConnected", nil, true, firstTime)
				
				firstTime = false
				
				if (callback_success) then
					callback_success()
				end
				
				for k, info in pairs(queue) do
					local queryObject = fchat.sql.remote.object:query(info.query)
		
					function queryObject:onSuccess(data)
						if (info.callback_success) then
							info.callback_success(data, self)
						end
					end
					
					function queryObject:onError(message, queryString)
						ServerLog("[fchat] The query \"" .. queryString .. "\" failed: " .. message .. "\n")
						
						if (info.callback_failed) then
							info.callback_failed(self, message, queryString)
						end
					end
					
					queryObject:start()
				end
				
				queue = {}
			end
			
			function database:onConnectionFailed(message)
				ServerLog("[fchat] MySQL connection failed: " .. tostring(message) .. "\n")
				
				if (callback_failed) then
					callback_failed(message)
				end
				
				-- Fallback to SQLite.
				hook.Call("fchat.DatabaseConnected", nil, false, firstTime)
				
				firstTime = false
			end

			database:connect()
		else
			fchat.sql.remote = {}
			
			ServerLog("[fchat] The module \"gmsv_mysqloo\" was not found. ( Failed to load? )\n")
			ServerLog("[fchat] Download and install the module: http://goo.gl/4A4ekH\n")
		end
	else
		hook.Call("fchat.DatabaseConnected", nil, false, firstTime)
		
		firstTime = false
	end
end

----------------------------------------------------------------------	
-- Purpose:
--		Initializes a query to the database.
----------------------------------------------------------------------

function fchat.sql.Query(query, callback_success, callback_failed)
	if (fchat.sql.remote.object) then
		local queryObject = fchat.sql.remote.object:query(query)
		
		function queryObject:onSuccess(data)
			if (callback_success) then
				callback_success(data, self)
			end
		end
		
		function queryObject:onError(message, queryString)
			ServerLog("[fchat] The query \"" .. queryString .. "\" failed: " .. message .. "\n")
			
			local status = fchat.sql.remote.object:status()
			
			if (status == mysqloo.DATABASE_NOT_CONNECTED) then
				table.insert(queue, {query = query, callback_success = callback_success, callback_failed = callback_failed})
				
				fchat.sql.Initialize()
			end
			
			if (callback_failed) then
				callback_failed(self, message, queryString)
			end
		end
		
		queryObject:start()
	else
		local data = sql.Query(query)
		
		if (data == false) then
			ServerLog("[fchat] The query \"" .. query .. "\" failed: " .. sql.LastError() .. "\n")
			
			if (callback_failed) then
				callback_failed()
			end
		else
			if (callback_success) then
				callback_success(data)
			end
		end
	end
end

----------------------------------------------------------------------	
-- Purpose:
--		Returns true if we're using mysql.
----------------------------------------------------------------------

function fchat.sql.IsRemote()
	return fchat.sql.remote.object != nil
end

----------------------------------------------------------------------	
-- Purpose:
--		Sends & changes information for mysql.
----------------------------------------------------------------------

util.AddNetworkString("fchat.myin")

net.Receive("fchat.myin", function(bits, player)
	local isAdmin = player:IsSuperAdmin()
	
	if (isAdmin) then
		local option = util.tobool(net.ReadBit())
		
		if (option) then
			local status = fchat.sql.remote.object and fchat.sql.remote.object:status() or -1
			local address = fchat.sql.remote.address or ""
			local port = tonumber(fchat.sql.remote.port) or 3306
			local username = fchat.sql.remote.user or ""
			local database = fchat.sql.remote.database or "fchat"
			
			net.Start("fchat.myin")
				net.WriteInt(status, 8)
				net.WriteString("")
				net.WriteString(address)
				net.WriteUInt(port, 16)
				net.WriteString(username)
				net.WriteString(database)
			net.Send(player)
		else
			local address = net.ReadString()
			local port = net.ReadUInt(16)
			local username = net.ReadString()
			local password = net.ReadString()
			local database = net.ReadString()
			
			if (fchat.sql.remote.address) then
				sql.Query("UPDATE " .. tableName .. " SET address = " .. sql.SQLStr(address) .. ", port = " .. port .. ", user = " .. sql.SQLStr(username) .. ", password = " .. sql.SQLStr(password) .. ", database = " .. sql.SQLStr(database))
			else
				sql.Query("INSERT INTO " .. tableName .. "(address, port, user, password, database) VALUES(" .. sql.SQLStr(address) .. ", " .. port .. ", " .. sql.SQLStr(username) .. ", " .. sql.SQLStr(password) .. ", " .. sql.SQLStr(database) .. ")")
			end
			
			if (!mysqloo) then
				local success, message = pcall(require, "mysqloo")
				
				if (!success) then
					ErrorNoHalt("[fchat] Could not find the mysqloo module: " .. tostring(message) .. "\n")
				end
			end

			net.Start("fchat.myin")
				net.WriteInt(mysqloo.DATABASE_CONNECTING, 8)
				net.WriteString("")
				net.WriteString(address)
				net.WriteUInt(port, 16)
				net.WriteString(username)
				net.WriteString(database)
			net.Send(player)
			
			-- Reconnect with the new information.
			fchat.sql.Initialize(function()
				net.Start("fchat.myin")
					net.WriteInt(mysqloo.DATABASE_CONNECTED, 8)
					net.WriteString("")
					net.WriteString(address)
					net.WriteUInt(port, 16)
					net.WriteString(username)
					net.WriteString(database)
				net.Send(player)
			end,
			
			function(message)
				net.Start("fchat.myin")
					net.WriteInt(mysqloo.DATABASE_NOT_CONNECTED, 8)
					net.WriteString(message)
					net.WriteString(address)
					net.WriteUInt(port, 16)
					net.WriteString(username)
					net.WriteString(database)
				net.Send(player)
			end)
		end
	end
end)

