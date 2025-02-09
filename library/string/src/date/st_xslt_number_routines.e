note

	description:

		"Support routines for xsl:number"

	library: "Gobo Eiffel String Library"
	copyright: "Copyright (c) 2004-2022, Colin Adams and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class ST_XSLT_NUMBER_ROUTINES

inherit

	ANY

	ST_IMPORTED_UNICODE_CHARACTER_CLASS_ROUTINES
		export {NONE} all end

	UC_IMPORTED_UNICODE_ROUTINES
		export {NONE} all end

	KL_IMPORTED_STRING_ROUTINES
		export {NONE} all end

feature -- Access

	Single_level: INTEGER = 1
			-- Level-numbering value from xsl:number

	Multiple_levels: INTEGER = 2
			-- Level-numbering value from xsl:number

	Any_level: INTEGER = 3
			-- Level-numbering value from xsl:number

	Simple_numbering: INTEGER = 4
			-- Level-numbering value from xsl:number

	selected_numberer (a_language: STRING): detachable ST_XSLT_NUMBERER
			-- Numberer corresponding to `a_language'
		require
			language_not_void: a_language /= Void
				-- TODO: is_valid string for xml:lang (i.e. RFC 3066 compliant)
		do
				-- TODO: use a plug-in table, with regxep perhaps?
				--  can provide a parrot scripting facility within gestalt
				-- Do we need the country argument from format-dateTime as well?
				-- Probably not - this can be an argument to the routines
			if a_language.count > 1 and then STRING_.same_string (a_language.substring (1, 2), "en") then
				create {ST_XSLT_NUMBERER_EN} Result
			end
		ensure
			instance_free: class
		end

	is_zeros_plus_one (a_picture: STRING): BOOLEAN
			-- Does `a_picture' consist of zero or more zeros followed by a one?
		require
			picture_not_empty: a_picture /= Void and then not a_picture.is_empty
		local
			a_unit, a_zero, a_count, an_index: INTEGER
		do
			if a_picture.count > 1 then
				a_unit := a_picture.code (a_picture.count).to_integer_32
				if is_one (a_unit) then
					from
						an_index := 1
						Result := True
						a_zero := a_unit - 1
						a_count := a_picture.count
					until
						Result = False or else an_index = a_count
					loop
						Result := a_picture.code (an_index).to_integer_32 = a_zero
						an_index := an_index + 1
					end
				end
			end
		ensure
			instance_free: class
		end

	decimal_digits_set (a_picture: STRING): STRING
			-- Set of decimal digits from 0 to 9
		require
			picture_not_empty: a_picture /= Void and then not a_picture.is_empty
			zeros_plus_one: is_zeros_plus_one (a_picture) or (a_picture.count = 1 and then is_one (a_picture.code (1).to_integer_32))
		local
			a_zero: NATURAL_32
			a_count: INTEGER
		do
			a_zero := a_picture.code (a_picture.count) - 1
			Result := ""
			from
				a_count := 0
			until
				a_count > 9
			loop
				Result := STRING_.appended_string (Result, unicode.natural_32_code_to_string (a_zero))
				a_zero := a_zero + 1
				a_count := a_count + 1
			end
		ensure
			instance_free: class
			decimal_digits_set_not_void: Result /= Void
			ten_digits: Result.count = 10
		end

	is_one (an_integer: INTEGER): BOOLEAN
			-- Is `an_integer' a Unicode code-point of decimal value 1?
		do
			Result := unicode_character_class.is_decimal_digit (an_integer) and then unicode_character_class.decimal_digit_value (an_integer) = 1
		ensure
			instance_free: class
		end

end
