note

	description:

		"Eiffel separate arguments at run-time"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2022, Eric Bezault and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class ET_DYNAMIC_SEPARATE_ARGUMENT

inherit

	ET_DYNAMIC_ATTACHMENT
		rename
			attachment as separate_argument
		end

create

	make

feature {NONE} -- Initialization

	make (a_source_type_set: like source_type_set; a_separate_argument: like separate_argument;
		a_current_feature: like current_feature; a_current_type: like current_type)
			-- Create a new object-test.
		require
			a_source_type_set_not_void: a_source_type_set /= Void
			a_separate_argument_not_void: a_separate_argument /= Void
			a_current_feature_not_void: a_current_feature /= Void
			a_current_type_not_void: a_current_type /= Void
		do
			source_type_set := a_source_type_set
			separate_argument := a_separate_argument
			current_feature := a_current_feature
			current_type := a_current_type
		ensure
			source_type_set_set: source_type_set = a_source_type_set
			separate_argument_set: separate_argument = a_separate_argument
			current_feature_set: current_feature = a_current_feature
			current_type_set: current_type = a_current_type
		end

feature -- Access

	separate_argument: ET_SEPARATE_ARGUMENT
			-- Separate argument

	position: ET_POSITION
			-- Position of attachment
		do
			Result := separate_argument.name.position
		end

	description: STRING = "separate_argument"
			-- Kind of attachment

invariant

	separate_argument_not_void: separate_argument /= Void

end
