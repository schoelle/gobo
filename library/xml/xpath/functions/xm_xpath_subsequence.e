indexing

	description:

		"Objects that implement the XPath subsequence() function"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_SUBSEQUENCE

inherit

	XM_XPATH_SYSTEM_FUNCTION
		redefine
			analyze, iterator
		end

	XM_XPATH_SHARED_ANY_ITEM_TYPE

creation

	make

feature {NONE} -- Initialization

	make is
			-- Establish invariant
		do
			name := "subsequence"
			minimum_argument_count := 2
			maximum_argument_count := 3
			create arguments.make (3)
			arguments.set_equality_tester (expression_tester)
			compute_static_properties
		end

feature -- Access

	item_type: XM_XPATH_ITEM_TYPE is
			-- Data type of the expression, where known
		do
			Result := any_item
			if Result /= Void then
				-- Bug in SE 1.0 and 1.1: Make sure that
				-- that `Result' is not optimized away.
			end
		end

feature -- Status report

	required_type (argument_number: INTEGER): XM_XPATH_SEQUENCE_TYPE is
			-- Type of argument number `argument_number'
		do
			inspect
				argument_number
			when 1 then
				create Result.make_any_sequence
			when 2 then
				create Result.make_single_double
			when 3 then
				create Result.make_single_double
			end
		end

feature -- Optimization

	analyze (a_context: XM_XPATH_STATIC_CONTEXT) is
			-- Perform static analysis of `Current' and its subexpressions.
		do
			clone_special_properties (arguments.item (1))
			Precursor (a_context)
		end

feature -- Evaluation

	iterator (a_context: XM_XPATH_CONTEXT): XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_ITEM] is
			-- An iterator over the values of a sequence
		local
			an_iterator: XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_ITEM]
			an_empty_iterator: XM_XPATH_EMPTY_ITERATOR [XM_XPATH_ITEM]
			an_item: XM_XPATH_ITEM
			a_double_value: XM_XPATH_DOUBLE_VALUE
			a_starting_location, a_final_position, a_length: INTEGER
		do
			an_iterator := arguments.item (1).iterator (a_context)
			an_empty_iterator ?= an_iterator
			if an_iterator.is_error then
				Result := an_iterator
			elseif an_empty_iterator /= Void then
				Result := an_empty_iterator
			else
				arguments.item (2).evaluate_item (a_context)
				an_item := arguments.item (2).last_evaluated_item
				check
					item_not_void: an_item /= Void
					-- static typing
				end
				if an_item.is_error then
					create {XM_XPATH_INVALID_ITERATOR} Result.make (an_item.error_value)
				else
					a_double_value ?= an_item
					check
						starting_location_is_double: a_double_value /= Void
						-- Static typing
					end
					a_double_value := a_double_value.rounded_value
					a_starting_location := a_double_value.as_integer
					if arguments.count = 2 then
						if a_starting_location <= 1 then
							Result := an_iterator
						else
							create {XM_XPATH_TAIL_ITERATOR} Result.make (an_iterator, a_starting_location)
						end
					else
						arguments.item (3).evaluate_item (a_context)
						an_item := arguments.item (3).last_evaluated_item
						check
							item_not_void: an_item /= Void
							-- static typing
						end
						if an_item.is_error then
							create {XM_XPATH_INVALID_ITERATOR} Result.make (an_item.error_value)
						else
							a_double_value ?= an_item
							check
								length_is_double: a_double_value /= Void
								-- Static typing
							end
							a_double_value := a_double_value.rounded_value
							a_length := a_double_value.as_integer
							a_final_position := a_length + a_starting_location - 1
							if a_starting_location <= 1 then a_starting_location := 1 end
							create {XM_XPATH_POSITION_ITERATOR} Result.make (an_iterator, a_starting_location, a_final_position)
						end
					end
				end
			end
		end

feature {XM_XPATH_EXPRESSION} -- Restricted

	compute_cardinality is
			-- Compute cardinality.
		do
			set_cardinality_zero_or_more
		end
	
end
	