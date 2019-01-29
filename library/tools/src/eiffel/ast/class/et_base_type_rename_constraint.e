note

	description:

	"[
		Eiffel constraints on formal generic parameters where the 
		actual generic parameters need to conform to just one type,
		which is a base type), and with a rename clause.
	]"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2019, Eric Bezault and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class ET_BASE_TYPE_RENAME_CONSTRAINT

inherit

	ET_BASE_TYPE_CONSTRAINT
		undefine
			renames,
			is_formal_parameter
		redefine
			type,
			named_query,
			named_procedure
		end

	ET_TYPE_RENAME_CONSTRAINT
		undefine
			type_constraint
		redefine
			type,
			process
		end

create

	make

feature -- Access

	type: ET_BASE_TYPE
			-- Type to which the actual generic parameters
			-- will need to conform

feature -- Features

	named_query (a_name: ET_CALL_NAME): detachable ET_QUERY
			-- Query named `a_name' in `type'.
			-- Take into account possible renaming with `renames'.
			-- Void if no such query.
		local
			l_index: INTEGER
		do
			l_index := renames.index_of_new_name (a_name)
			if l_index /= 0 then
				Result := type.base_class.queries.named_feature (renames.rename_pair (l_index).old_name)
			elseif attached type.base_class.queries.named_feature (a_name) as l_query and then renames.index_of_old_name (l_query.name) = 0 then
				Result := l_query
			end
		end

	named_procedure (a_name: ET_CALL_NAME): detachable ET_PROCEDURE
			-- Procedure named `a_name' in `type'.
			-- Take into account possible renaming with `renames'.
			-- Void if no such procedure.
		local
			l_index: INTEGER
		do
			l_index := renames.index_of_new_name (a_name)
			if l_index /= 0 then
				Result := type.base_class.procedures.named_feature (renames.rename_pair (l_index).old_name)
			elseif attached type.base_class.procedures.named_feature (a_name) as l_procedure and then renames.index_of_old_name (l_procedure.name) = 0 then
				Result := l_procedure
			end
		end

feature -- Processing

	process (a_processor: ET_AST_PROCESSOR)
			-- Process current node.
		do
			a_processor.process_base_type_rename_constraint (Current)
		end

end