<!--- 
Title:      JavaLoaderFactory.cfc

Source:     https://github.com/jamiekrug/JavaLoaderFactory

Author:     Jamie Krug
            http://identi.ca/jamiekrug
            http://twitter.com/jamiekrug
            http://jamiekrug.com/blog/
			(converted to CF8-compliant tag-based structure by Rich Rein)

Purpose:    Factory to provide facade to server-scoped instance of
            JavaLoader (http://javaloader.riaforge.org/).

Example ColdSpring bean factory configuration:

	<bean id="javaLoaderFactory" class="JavaLoaderFactory.JavaLoaderFactory" />

	<bean id="javaLoader" factory-bean="javaLoaderFactory" factory-method="getJavaLoader">
		<constructor-arg name="loadPaths">
			<list>
				<value>/opt/XOM/xom-1.2.6.jar</value>
			</list>
		</constructor-arg>
		<constructor-arg name="loadRelativePaths">
			<list>
				<value>/../jars/opencsv-2.2.jar</value>
			</list>
		</constructor-arg>
	</bean>

Example usage:

	javaLoader = getBeanFactory().getBean( 'javaLoader' );

	csvReader = javaLoader.create( 'au.com.bytecode.opencsv.CSVReader' );
 --->

<cfcomponent displayname="JavaLoaderFactory" output="false" hint="Factory to provide facade to server-scoped instance of JavaLoader (http://javaloader.riaforge.org/)">
	<cffunction name="init" access="public" output="false" returntype="any" hint="Pseudo-constructor">
		<cfargument name="lockTimeout" required="false" default="60" type="numeric" hint="" />
		<cfargument name="serverKey" required="false" default="" type="string" hint="" />
		
		<cfset variables.lockTimeout = arguments.lockTimeout />
		<cfset variables.serverKey = arguments.lockTimeout />
		
		<cfif StructKeyExists(arguments, "serverKey") and arguments.serverKey neq "">
			<cfset variables.serverKey = arguments.serverKey />
		</cfif>
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getJavaLoader" access="public" output="false" returntype="any" hint="returns a reference to the appropriate javaloader">
		<cfargument name="loadPaths" required="false" default="#ArrayNew(1)#" type="array" hint="" />
		<cfargument name="loadColdFusionClassPath" required="false" default="false" type="boolean" hint="" />
		<cfargument name="parentClassLoader" required="false" default="" type="string" hint="" />
		<cfargument name="sourceDirectories" required="false" default="#ArrayNew(1)#" type="array" hint="" />
		<cfargument name="compileDirectory" required="false" default="" type="string" hint="" />
		<cfargument name="trustedSource" required="false" default="false" type="boolean" hint="" />
		<cfargument name="loadRelativePaths" required="false" default="#ArrayNew(1)#" type="array" hint="" />
		
		<cfset var javaLoaderInitArgs = buildJavaLoaderInitArgs(argumentCollection = arguments) />

		<cfset var _serverKey = calculateServerKey(javaLoaderInitArgs) />

		<cfif not structKeyExists(server, _serverKey)>
			<cflock name="server.#_serverKey#" timeout="#variables.lockTimeout#">
				<cfif not structKeyExists(server, _serverKey)>
					<cfset server[ _serverKey ] = createObject('component', 'com.compoundtheory.JavaLoader').init(argumentCollection = javaLoaderInitArgs) />
				</cfif>
			</cflock>
		</cfif>

		<cfreturn server[ _serverKey ] />
	</cffunction>

	<cffunction name="buildJavaLoaderInitArgs" access="private" output="false" returntype="struct" hint="">
		<cfargument name="loadPaths" required="false" default="#ArrayNew(1)#" type="array" hint="" />
		<cfargument name="loadColdFusionClassPath" required="false" default="false" type="boolean" hint="" />
		<cfargument name="parentClassLoader" required="false" default="" type="string" hint="" />
		<cfargument name="sourceDirectories" required="false" default="#ArrayNew(1)#" type="array" hint="" />
		<cfargument name="compileDirectory" required="false" default="" type="string" hint="" />
		<cfargument name="trustedSource" required="false" default="false" type="boolean" hint="" />
		<cfargument name="loadRelativePaths" required="false" default="#ArrayNew(1)#" type="array" hint="" />
		
		<cfset var initArgs = {} />
		<cfset var argName = "" />
		<cfset var lstPossibleArgs = "loadPaths,loadColdFusionClassPath,parentClassLoader,sourceDirectories,compileDirectory,trustedSource" />
		<cfset var relPath = "" />

		<cfloop index="argName" list="#lstPossibleArgs#"> 
			<cfif structKeyExists(arguments, argName)>
				<cfset initArgs[ argName ] = arguments[ argName ] />
			</cfif>
		</cfloop>

		<cfif structKeyExists( arguments, 'loadRelativePaths' ) && arrayLen( arguments.loadRelativePaths )>
			<cfif not structKeyExists( initArgs, 'loadPaths' )>
				<cfset initArgs.loadPaths = [] />
			</cfif>

			<cfloop index="relPath" array="#arguments.loadRelativePaths#">
				<cfset arrayAppend(initArgs.loadPaths, expandPath(relPath)) />
			</cfloop>
		</cfif>

		<cfreturn initArgs />
	</cffunction>

	<cffunction name="calculateServerKey" access="private" output="false" returntype="string" hint="">
		<cfargument name="javaLoaderInitArgs" required="false" default="" type="struct" hint="" />

		<!--- variables.serverKey takes precedence, if exists --->
		<cfif structKeyExists(variables, "serverKey")>
			<cfreturn variables.serverKey />
		</cfif>

		<!--- hash init args, to generate unique key based on precise JavaLoader instance --->
		<cfreturn "Test#CreateUUID()#" />
		<!--- couldn't get this working right yet --->
		<!--- <cfreturn hash(serializeJSON({javaLoader = arguments.javaLoaderInitArgs})) /> --->
	</cffunction>
</cfcomponent>