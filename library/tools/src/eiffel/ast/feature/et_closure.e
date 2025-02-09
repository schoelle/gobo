note

	description:

		"Eiffel closures, e.g. features, invariants, inline agents"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2006-2022, Eric Bezault and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

deferred class ET_CLOSURE

inherit

	ANY

feature -- Status report

	is_once: BOOLEAN
			-- Is current closure a once feature?
		do
			-- Result := False
		end

	is_once_per_process: BOOLEAN
			-- Is current closure a once-per-process feature?
		do
			-- Result := False
		ensure
			is_once: Result implies is_once
		end

	is_once_per_thread: BOOLEAN
			-- Is current closure a once-per-thread feature?
		do
			-- Result := False
		ensure
			is_once: Result implies is_once
		end

	is_once_per_object: BOOLEAN
			-- Is current closure a once-per-object feature?
		do
			-- Result := False
		ensure
			is_once: Result implies is_once
		end

feature -- Access

	type: detachable ET_TYPE
			-- Return type;
			-- Void for procedures
		do
		end

	arguments: detachable ET_FORMAL_ARGUMENT_LIST
			-- Formal arguments;
			-- Void if no arguments
		do
		end

	first_indexing: detachable ET_INDEXING_LIST
			-- Note clause at the beginning of the closure
		do
		end

	locals: detachable ET_LOCAL_VARIABLE_LIST
			-- Local variables;
			-- Void if no local variables
		do
		end

	preconditions: detachable ET_PRECONDITIONS
			-- Preconditions;
			-- Void if no preconditions
		do
		end

	postconditions: detachable ET_POSTCONDITIONS
			-- Postconditions;
			-- Void if no postconditions
		do
		end

	object_tests: detachable ET_OBJECT_TEST_LIST
			-- Object-tests declared in current closure;
			-- Void if none

	iteration_components: detachable ET_ITERATION_COMPONENT_LIST
			-- Iteration components declared in current closure;
			-- Void if none

	separate_arguments: detachable ET_SEPARATE_ARGUMENT_LIST
			-- Separate arguments (in separate instructions) declared in current closure;
			-- Void if none

	implementation_closure: ET_CLOSURE
			-- Current closure viewed from the class where it has been implemented
			--
			-- Useful for interpreting feature calls and type anchors (that might
			-- be renamed in descendant classes) when features are inherited as-is.
		do
			Result := Current
		ensure
			implementation_closure_not_void: Result /= Void
		end

feature -- Setting

	set_object_tests (a_object_tests: like object_tests)
			-- Set `object_tests' to `a_object_tests'.
		do
			object_tests := a_object_tests
		ensure
			object_tests_set: object_tests = a_object_tests
		end

	set_iteration_components (a_iteration_components: like iteration_components)
			-- Set `iteration_components' to `a_iteration_components'.
		do
			iteration_components := a_iteration_components
		ensure
			iteration_components_set: iteration_components = a_iteration_components
		end

	set_separate_arguments (a_separate_arguments: like separate_arguments)
			-- Set `separate_arguments' to `a_separate_arguments'.
		do
			separate_arguments := a_separate_arguments
		ensure
			separate_arguments_set: separate_arguments = a_separate_arguments
		end

end
