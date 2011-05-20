<!--- 
Title:      JavaLoaderFactoryBean.cfc

Web site:   https://github.com/jamiekrug/JavaLoaderFactory

Author:     Jamie Krug
            http://identi.ca/jamiekrug
            http://twitter.com/jamiekrug
            http://jamiekrug.com/blog/
			(converted to CF8-compliant tag-based structure by Rich Rein)

Purpose:    ColdSpring factory bean to provide facade to server-scoped JavaLoader instance.

Example ColdSpring bean factory configuration:

	<bean id="javaLoader" class="JavaLoaderFactory.JavaLoaderFactoryBean">
		<property name="loadRelativePaths">
			<list>
				<value>/../jars/opencsv-2.2.jar</value>
			</list>
		</property>
		<property name="loadPaths">
			<list>
				<value>/opt/XOM/xom-1.2.6.jar</value>
			</list>
		</property>
	</bean>

Example usage:

	javaLoader = getBeanFactory().getBean( 'javaLoader' );

	csvReader = javaLoader.create( 'au.com.bytecode.opencsv.CSVReader' );
 --->

<cfcomponent displayname="JavaLoaderFactoryBean" output="false" extends="coldspring.beans.factory.FactoryBean" hint="ColdSpring factory bean to provide facade to server-scoped JavaLoader instance.">
	<cfproperty name="loadRelativePaths" type="array" default="#ArrayNew(1)#" hint="Relative paths that will be expanded and appended to loadPaths." />
	<cfproperty name="lockTimeout" type="numeric" default="60" hint="Timeout, in seconds, for named lock used when instantiating JavaLoader instance in server scope." />
	<cfproperty name="objectType" type="string" default="JavaLoader.JavaLoader" hint="Component path to JavaLoader, to allow for a non-standard CFC location (default is com.compound.JavaLoader)." />
	<cfproperty name="serverKey" type="string" default="" hint="Server struct key to hold JavaLoader instance; recommend **not** specifying this argument, but it's here if you really want it." />
	<cfproperty name="loadPaths" type="array" default="#ArrayNew(1)#" hint="See JavaLoader:init()" />
	<cfproperty name="loadColdFusionClassPath" type="boolean" default="false" hint="See JavaLoader:init()" />
	<cfproperty name="parentClassLoader" type="string" default="" hint="See JavaLoader:init()" />
	<cfproperty name="sourceDirectories" type="array" default="#ArrayNew(1)#" hint="See JavaLoader:init()" />
	<cfproperty name="compileDirectory" type="string" default="" hint="See JavaLoader:init()" />
	<cfproperty name="trustedSource" type="boolean" default="false" hint="See JavaLoader:init()" />
	<cfproperty name="loadRelativePaths" type="array" default="#ArrayNew(1)#" hint="See JavaLoader:init()" />

	<cffunction name="init" access="public" output="false" returntype="any" hint="Pseudo-constructor">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="onMissingMethod" access="public" returnType="any" output="false" hint="used for implicit getters and setters (converted from CF9-specific accessors=true)">
		<cfargument name="missingMethodName" type="tring" required="true" />
		<cfargument name="missingMethodArguments" type="struct" required="true" />
		
		<cfset var key = "" />
		
		<!--- this includes arguments with set --->
		<cfif left(arguments.missingMethodName,3) eq "get">
			<cfset key = replaceNoCase(arguments.missingMethodName,"get","") />
			<cfif structKeyExists(variables, key)>
				<cfreturn variables[key] />
			</cfif>
		</cfif>
		
		<!--- this includes arguments with set --->
		<cfif left(arguments.missingMethodName,3) eq "set">
			<cfset key = replaceNoCase(arguments.missingMethodName,"set","") />
			<cfif structKeyExists(arguments.missingMethodArguments, key)>
				<cfset variables[key] = arguments.missingMethodArguments[key] />
			</cfif>
		</cfif>
		
		<!--- everything else still throws an error --->	
	</cffunction>

	<cffunction name="getObject" access="public" output="false" returntype="any" hint="Create/return server-scoped JavaLoader instance.">
		<cfset initLoadPaths() />

		<cfset initServerKey() />

		<cfif not structKeyExists(server, getServerKey())>
			<cflock name="#getLockName()#" timeout="#getLockTimeout()#">
				<cfif not structKeyExists(server, getServerKey())>
					<cfset server[getServerKey()] = createObject("component", getObjectType()).init(argumentCollection = getJavaLoaderInitArgs()) />
				</cfif>
			</cflock>
		</cfif>

		<cfreturn server[getServerKey()] />
	</cffunction>

	<cffunction name="getObjectType" access="public" output="false" returntype="string" hint="">
		<cfreturn variables.objectType />
	</cffunction>
	
	<cffunction name="isSingleton" access="public" output="false" returntype="boolean" hint="">
		<cfreturn true />
	</cffunction>


	<cffunction name="createServerKey" access="private" output="false" returntype="string" hint="Create a server key unique to JavaLoader instance by hashing init args and objectType.">
		<cfreturn "Test#CreateUUID()#" />
		<!--- couldn't get this working right yet --->
		<!--- <cfreturn hash(serializeJSON({'#getObjectType()#' = getJavaLoaderInitArgs()})) /> --->
	</cffunction>


	<cffunction name="getJavaLoaderInitArgs" access="private" output="false" returntype="struct" hint="Argument collection for JavaLoader:init().">
		<cfset var stJavaLoaderInitArgs = StructNew() />
		<cfset stJavaLoaderInitArgs.loadPaths = getLoadPaths() />
		<cfset stJavaLoaderInitArgs.loadColdFusionClassPath = getLoadColdFusionClassPath() />
		<cfset stJavaLoaderInitArgs.parentClassLoader = getParentClassLoader() />
		<cfset stJavaLoaderInitArgs.sourceDirectories = getSourceDirectories() />
		<cfset stJavaLoaderInitArgs.compileDirectory = getCompileDirectory() />
		<cfset stJavaLoaderInitArgs.trustedSource = getTrustedSource() />
		
		<cfreturn stJavaLoaderInitArgs />	
	</cffunction>


	<cffunction name="getLockName" access="private" output="false" returntype="string" hint="returns the variable name of the lock">
		<cfreturn "server.#getServerKey()#" />
	</cffunction>


	<cffunction name="initLoadPaths" access="private" output="false" returntype="void" hint="Initialize JavaLoader load paths by appending any relative paths (loadRelativePaths), expanded, to any absolute paths (loadPaths).">
		<cfset var loadPaths = [] />
		<cfset var relPath = "" />
		
		<cfif ArrayLen(getLoadRelativePaths()) gt 0>
			<cfif ArrayLen(getLoadPaths()) gt 0>
				<cfset loadPaths = getLoadPaths() />
			</cfif>

			<cfloop index="relPath" array="#getLoadRelativePaths()#">
				<cfset arrayAppend(loadPaths, expandPath(relPath)) />
			</cfloop>

			<cfset setLoadPaths(loadPaths) />

			<cfset setLoadRelativePaths([]) />
		</cfif>
	</cffunction>

	<cffunction name="initServerKey" access="private" output="false" returntype="void" hint="Initialize server key name to hold JavaLoader instance, if not explicitly provided.">
		<cfif Len(Trim(getServerKey())) eq 0>
			<cfset setServerKey(createServerKey()) />
		</cfif>
	</cffunction>
</cfcomponent>