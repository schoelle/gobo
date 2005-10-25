indexing

	description:

		"Gobo Eiffel generator for Unicode Classes"

	copyright: "Copyright (c) 2005, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class GEUC

inherit

	KL_SHARED_ARGUMENTS
		export {NONE} all end

	KL_SHARED_EXCEPTIONS
		export {NONE} all end

	KL_IMPORTED_STRING_ROUTINES
		export {NONE} all end

	KL_IMPORTED_INTEGER_ROUTINES
		export {NONE} all end

	GEUC_CONSTANTS
	
create

	execute
	
feature -- Execution

	execute is
			-- Start 'geuc' execution.
		do
			Arguments.set_program_name ("geuc")
			create error_handler.make_standard
			process_command_line
			create code_points.make (0, maximum_unicode_character_code)
			parse_character_classes
			generate_character_class_routines
			generate_lower_case_routines
			generate_upper_case_routines
			generate_title_case_routines
		end

feature -- processing

	process_command_line is
			-- Process command line arguments.
		local
			nb: INTEGER
			arg: STRING
		do
			nb := Arguments.argument_count
			if nb = 0 then
				file_name_prefix := "uc_"
			elseif nb = 1 then
				arg := Arguments.argument (1)
				if arg.count > 10 and then arg.substring (1, 13).is_equal ("--uc_version=") then
					file_name_prefix := "uc_" + arg.substring (14, arg.count).as_lower + "_"
				else
					report_general_message ("Usage is geuc [--uc_version=<version-prefix>]")
					Exceptions.die (1)
				end
			else
				report_general_message ("Too many arguments")
				report_general_message ("Usage is geuc [--uc_version=<version-prefix>]")
				Exceptions.die (1)
			end
		ensure
			file_name_prefix_void: file_name_prefix /= Void
		end

	parse_character_classes is
			-- Parse "UnicodeData.txt" for character classes, etc.
		local
			a_file: KL_TEXT_INPUT_FILE
			a_splitter: ST_SPLITTER
			some_fields: DS_LIST [STRING]
			a_hex_code_point, a_name: STRING
			a_code_point, an_index: INTEGER
		do
			create a_file.make ("UnicodeData.txt")
			create a_splitter.make_with_separators (";")
			a_file.open_read
			if a_file.is_open_read then
				from  until a_file.end_of_file loop
					a_file.read_line
					if not a_file.end_of_file then
						some_fields := a_splitter.split_greedy (a_file.last_string)
						if some_fields.count /= Field_count then
							report_general_message ("Bad data line in UnicodeData.txt - not enpoug fields - data line is: " + a_file.last_string)
							Exceptions.die (1)
						else
							a_hex_code_point := some_fields.item (1)
							a_name := some_fields.item (2)
							if STRING_.is_hexadecimal (a_hex_code_point) then
								a_code_point := STRING_.hexadecimal_to_integer (a_hex_code_point)
								if is_range_start (a_name) then
									initial_code_point := a_code_point
								elseif is_range_finish (a_name) then
									if initial_code_point <= 0 or else initial_code_point > a_code_point then
										report_general_message ("Invalid start range - data line for end of range is: " + a_file.last_string)
										Exceptions.die (1)
									else
										from an_index := initial_code_point until an_index > a_code_point loop
											process_code_point_class (an_index, a_name.substring (2, a_name.count - 7), some_fields)
											an_index := an_index + 1
										end
									end
								else
									process_code_point_class (a_code_point, a_name, some_fields)
								end
							else
								report_general_message ("Invalid code point - data line is: " + a_file.last_string)
								Exceptions.die (1)
							end
						end
					end
				end
			else
				report_general_message ("Unable to open file UnicodeData.txt for reading")
				Exceptions.die (1)
			end
		end

	process_code_point_class (a_code_point: INTEGER; a_name: STRING; some_fields: DS_LIST [STRING]) is
			-- Process character class et. el. for `a_code_point'.
		require
			name_exists: a_name /= Void
			fifteen_fields: some_fields /= Void and then some_fields.count = Field_count
		local
			a_data_point: GEUC_UNICODE_DATA
		do
			create a_data_point.make (a_code_point, a_name, some_fields)
			if a_data_point.is_valid then
				code_points.put (a_data_point, a_code_point)
			else
				report_general_message ("Invalid code point: " + a_code_point.out)
				Exceptions.die (1)
			end
		end

feature -- Code generation

	file_name_prefix: STRING
			-- Prefix for generated file names

	class_name_prefix: STRING is
			-- Prefix for generated class names
		require
			file_name_prefix_exists: file_name_prefix /= Void
		do
			Result := file_name_prefix.as_upper
		ensure
			class_name_prefix_not_void: Result /= Void
		end

	generate_character_class_routines is
			-- Generate character class routines from `code_points' data.
		require
			code_points_exist: code_points /= Void
			file_name_prefix_exists: file_name_prefix /= Void
			class_name_prefix_exists: class_name_prefix /= Void
		local
			an_output_file:  KL_TEXT_OUTPUT_FILE
		do
			create an_output_file.make (file_name_prefix + "character_class_routines.e")
			an_output_file.open_write
			an_output_file.put_string ("indexing%N%N")
			an_output_file.put_string ("%Tdescription:%N%N")
			an_output_file.put_string ("%T%T%"Routines for determining class of Unicode characters%"%N%N")
			an_output_file.put_string ("%Tremark:%N%N")
			an_output_file.put_string ("%T%T%"Generated by geuc%"%N%N")
			an_output_file.put_string ("%Tlibrary: %"Gobo Eiffel Kernel Library%"%N")
			an_output_file.put_string ("%Tcopyright: %"Copyright (c) 2005, Colin Adams and others%"%N")
			an_output_file.put_string ("%Tlicense: %"Eiffel Forum License v2 (see forum.txt)%"%N")
			an_output_file.put_string ("%Tdate: %"$Date$%"%N")
			an_output_file.put_string ("%Trevision: %"$Revision$%"%N%N")
			an_output_file.put_string ("class ")
			an_output_file.put_string (class_name_prefix)
			an_output_file.put_string ("CHARACTER_CLASS_ROUTINES%N%N")
			an_output_file.put_string ("inherit%N%N%TUC_CHARACTER_CLASS_INTERFACE%N%N")
			an_output_file.put_string ("feature {NONE} -- Implementation%N%N")
			write_character_class_array (an_output_file)
			write_decimal_value_array (an_output_file)
			an_output_file.put_string ("end%N")
			an_output_file.close
		end

	generate_lower_case_routines is
			-- Generate lower-case routines from `code_points' data.
		require
			code_points_exist: code_points /= Void
			file_name_prefix_exists: file_name_prefix /= Void
			class_name_prefix_exists: class_name_prefix /= Void
		local
			an_output_file:  KL_TEXT_OUTPUT_FILE
		do
			create an_output_file.make (file_name_prefix + "ctype_lowercase.e")
			an_output_file.open_write
			an_output_file.put_string ("indexing%N%N")
			an_output_file.put_string ("%Tdescription:%N%N")
			an_output_file.put_string ("%T%T%"Database for simple mapping to lower case%"%N%N")
			an_output_file.put_string ("%Tremark:%N%N")
			an_output_file.put_string ("%T%T%"Generated by geuc%"%N%N")
			an_output_file.put_string ("%Tlibrary: %"Gobo Eiffel Kernel Library%"%N")
			an_output_file.put_string ("%Tcopyright: %"Copyright (c) 2005, Colin Adams and others%"%N")
			an_output_file.put_string ("%Tlicense: %"Eiffel Forum License v2 (see forum.txt)%"%N")
			an_output_file.put_string ("%Tdate: %"$Date$%"%N")
			an_output_file.put_string ("%Trevision: %"$Revision$%"%N%N")
			an_output_file.put_string ("class ")
			an_output_file.put_string (class_name_prefix)
			an_output_file.put_string ("CTYPE_LOWERCASE%N%N")
			an_output_file.put_string ("inherit%N%N%TKL_IMPORTED_INTEGER_ROUTINES%N%T%Texport {NONE} all end%N%N")
			an_output_file.put_string ("feature {NONE} -- Implementation%N%N")
			write_lower_case_array (an_output_file)
			an_output_file.put_string ("end%N")
			an_output_file.close
		end

	generate_upper_case_routines is
			-- Generate upper-case routines from `code_points' data.
		require
			code_points_exist: code_points /= Void
			file_name_prefix_exists: file_name_prefix /= Void
			class_name_prefix_exists: class_name_prefix /= Void
		local
			an_output_file:  KL_TEXT_OUTPUT_FILE
		do
			create an_output_file.make (file_name_prefix + "ctype_uppercase.e")
			an_output_file.open_write
			an_output_file.put_string ("indexing%N%N")
			an_output_file.put_string ("%Tdescription:%N%N")
			an_output_file.put_string ("%T%T%"Database for simple mapping to upper case%"%N%N")
			an_output_file.put_string ("%Tremark:%N%N")
			an_output_file.put_string ("%T%T%"Generated by geuc%"%N%N")
			an_output_file.put_string ("%Tlibrary: %"Gobo Eiffel Kernel Library%"%N")
			an_output_file.put_string ("%Tcopyright: %"Copyright (c) 2005, Colin Adams and others%"%N")
			an_output_file.put_string ("%Tlicense: %"Eiffel Forum License v2 (see forum.txt)%"%N")
			an_output_file.put_string ("%Tdate: %"$Date$%"%N")
			an_output_file.put_string ("%Trevision: %"$Revision$%"%N%N")
			an_output_file.put_string ("class ")
			an_output_file.put_string (class_name_prefix)
			an_output_file.put_string ("CTYPE_UPPERCASE%N%N")
			an_output_file.put_string ("inherit%N%N%TKL_IMPORTED_INTEGER_ROUTINES%N%T%Texport {NONE} all end%N%N")
			an_output_file.put_string ("feature {NONE} -- Implementation%N%N")
			write_upper_case_array (an_output_file)
			an_output_file.put_string ("end%N")
			an_output_file.close
		end
	
	generate_title_case_routines is
			-- Generate title-case routines from `code_points' data.
		require
			code_points_exist: code_points /= Void
			file_name_prefix_exists: file_name_prefix /= Void
			class_name_prefix_exists: class_name_prefix /= Void
		local
			an_output_file:  KL_TEXT_OUTPUT_FILE
		do
			create an_output_file.make (file_name_prefix + "ctype_titlecase.e")
			an_output_file.open_write
			an_output_file.put_string ("indexing%N%N")
			an_output_file.put_string ("%Tdescription:%N%N")
			an_output_file.put_string ("%T%T%"Database for simple mapping to title case%"%N%N")
			an_output_file.put_string ("%Tremark:%N%N")
			an_output_file.put_string ("%T%T%"Generated by geuc%"%N%N")
			an_output_file.put_string ("%Tlibrary: %"Gobo Eiffel Kernel Library%"%N")
			an_output_file.put_string ("%Tcopyright: %"Copyright (c) 2005, Colin Adams and others%"%N")
			an_output_file.put_string ("%Tlicense: %"Eiffel Forum License v2 (see forum.txt)%"%N")
			an_output_file.put_string ("%Tdate: %"$Date$%"%N")
			an_output_file.put_string ("%Trevision: %"$Revision$%"%N%N")
			an_output_file.put_string ("class ")
			an_output_file.put_string (class_name_prefix)
			an_output_file.put_string ("CTYPE_TITLECASE%N%N")
			an_output_file.put_string ("inherit%N%N%TKL_IMPORTED_INTEGER_ROUTINES%N%T%Texport {NONE} all end%N%N")
			an_output_file.put_string ("feature {NONE} -- Implementation%N%N")
			write_title_case_array (an_output_file)
			an_output_file.put_string ("end%N")
			an_output_file.close
		end

	Empty_character_class_segment_array_name: STRING is "empty_character_class_segment"
			-- Name for empty character class segment

	Empty_character_class_plane_array_name: STRING is "empty_character_class_plane"
			-- Name for empty character class plane

	Empty_decimal_value_segment_array_name: STRING is "empty_decimal_value_segment"
			-- Name for empty decimal value segment

	Empty_decimal_value_plane_array_name: STRING is "empty_decimal_value_plane"
			-- Name for empty decimal value plane

	Empty_lower_code_segment_array_name: STRING is "empty_lower_code_segment"
			-- Name for empty lower code segment

	Empty_lower_code_plane_array_name: STRING is "empty_lower_code_plane"
			-- Name for empty lower_code plane

	Empty_upper_code_segment_array_name: STRING is "empty_upper_code_segment"
			-- Name for empty upper code segment

	Empty_upper_code_plane_array_name: STRING is "empty_upper_code_plane"
			-- Name for empty upper_code plane

	Empty_title_code_segment_array_name: STRING is "empty_title_code_segment"
			-- Name for empty title code segment

	Empty_title_code_plane_array_name: STRING is "empty_title_code_plane"
			-- Name for empty title_code plane	

	write_character_class_array (an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an Eiffel `ARRAY' containing character classes
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
		local
			i, j, k, a_code_point: INTEGER
			a_category: INTEGER
			a_code_point_datum: GEUC_UNICODE_DATA
			some_segment_names, some_plane_names: ARRAY [STRING]
			a_segment: ARRAY [INTEGER_8]
			plane_all_absent, segment_all_absent: BOOLEAN
			empty_plane_written, empty_segment_written: BOOLEAN
			a_plane_array_name, a_segment_array_name: STRING
		do
			create some_plane_names.make (0, 15)
			from i := 0 until i > 15 loop
				create some_segment_names.make (0, 255)
				from plane_all_absent := True; j := 0 until j > 255 loop
					create a_segment.make (0, 255)
					from segment_all_absent := True; k := 0 until k > 255 loop
						a_code_point := k + 256 * j + 256 * 256 * i
						a_code_point_datum := code_points.item (a_code_point)
						if a_code_point_datum = Void then
							a_category := Unassigned_other_category
						else
							a_category := a_code_point_datum.general_category
							if a_category /= Unassigned_other_category then
								segment_all_absent := False
								plane_all_absent := False
							end
						end
						a_segment.put (INTEGER_.to_integer_8 (a_category), k)
						k := k + 1
					end
					if segment_all_absent then
						a_segment_array_name := Empty_character_class_segment_array_name
						if not empty_segment_written then
							empty_segment_written := True
							write_integer8_segment (a_segment, Empty_character_class_segment_array_name, an_output_file)
						end
					else
						a_segment_array_name := "character_class_plane_" + (i+1).out + "_segment_" + (j+1).out
						write_integer8_segment (a_segment, a_segment_array_name, an_output_file)
					end
					some_segment_names.put (a_segment_array_name, j)
					j := j + 1
				end
				if plane_all_absent then
					a_plane_array_name := Empty_character_class_plane_array_name
					if not empty_plane_written then
						empty_plane_written := True
						write_empty_integer8_plane (a_plane_array_name, Empty_character_class_segment_array_name, an_output_file)
					end
				else
					a_plane_array_name := "character_class_plane_" + (i+1).out
					write_integer8_plane (some_segment_names, a_plane_array_name, an_output_file)
				end
				some_plane_names.put (a_plane_array_name, i)
				i := i + 1
			end
			an_output_file.put_string ("%Tcharacter_classes: ARRAY [ARRAY [ARRAY [INTEGER_8]]] is%N")
			an_output_file.put_string ("%T%T%T-- Character class for each code point%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 15)%N")
			from i := 0 until i > 15 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_plane_names.item (i))
				an_output_file.put_string (", ")
				an_output_file.put_string (i.out)
				an_output_file.put_string (")%N")
				i := i + 1
			end
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	write_decimal_value_array (an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an Eiffel `ARRAY' containing decimal digit values
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
		local
			i, j, k, a_code_point, a_category: INTEGER
			a_value: INTEGER_8
			a_code_point_datum: GEUC_UNICODE_DATA
			some_segment_names, some_plane_names: ARRAY [STRING]
			a_segment: ARRAY [INTEGER_8]
			plane_all_absent, segment_all_absent: BOOLEAN
			empty_plane_written, empty_segment_written: BOOLEAN
			a_plane_array_name, a_segment_array_name: STRING
		do
			create some_plane_names.make (0, 15)
			from i := 0 until i > 15 loop
				create some_segment_names.make (0, 255)
				from plane_all_absent := True; j := 0 until j > 255 loop
					create a_segment.make (0, 255)
					from segment_all_absent := True; k := 0 until k > 255 loop
						a_code_point := k + 256 * j + 256 * 256 * i
						a_code_point_datum := code_points.item (a_code_point)
						if a_code_point_datum = Void then
							a_value := Bad_decimal_value
						else
							a_category := a_code_point_datum.general_category
							if a_category = Decimal_digit_number_category then
								segment_all_absent := False; plane_all_absent := False
								a_value := a_code_point_datum.decimal_digit_value
							else
								a_value := Bad_decimal_value
							end
						end
						a_segment.put (a_value, k)
						k := k + 1
					end
					if segment_all_absent then
						a_segment_array_name := Empty_decimal_value_segment_array_name
						if not empty_segment_written then
							empty_segment_written := True
							write_integer8_segment (a_segment, Empty_decimal_value_segment_array_name, an_output_file)
						end
					else
						a_segment_array_name := "decimal_value_plane_" + (i+1).out + "_segment_" + (j+1).out
						write_integer8_segment (a_segment, a_segment_array_name, an_output_file)
					end
					some_segment_names.put (a_segment_array_name, j)
					j := j + 1
				end
				if plane_all_absent then
					a_plane_array_name := Empty_decimal_value_plane_array_name
					if not empty_plane_written then
						empty_plane_written := True
						write_empty_integer8_plane (a_plane_array_name, Empty_decimal_value_segment_array_name, an_output_file)
					end
				else
					a_plane_array_name := "decimal_value_plane_" + (i+1).out
					write_integer8_plane (some_segment_names, a_plane_array_name, an_output_file)
				end
				some_plane_names.put (a_plane_array_name, i)
				i := i + 1
			end
			an_output_file.put_string ("%Tdecimal_values: ARRAY [ARRAY [ARRAY [INTEGER_8]]] is%N")
			an_output_file.put_string ("%T%T%T-- Decimal value for each code point%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 15)%N")
			from i := 0 until i > 15 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_plane_names.item (i))
				an_output_file.put_string (", ")
				an_output_file.put_string (i.out)
				an_output_file.put_string (")%N")
				i := i + 1
			end
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	write_lower_case_array (an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an Eiffel `ARRAY' containing lower case equivalents.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
		local
			i, j, k, a_code_point, a_value: INTEGER			
			a_code_point_datum: GEUC_UNICODE_DATA
			some_segment_names, some_plane_names: ARRAY [STRING]
			plane_all_absent, segment_all_absent: BOOLEAN
			empty_plane_written, empty_segment_written: BOOLEAN
			a_segment: ARRAY [INTEGER]
			a_plane_array_name, a_segment_array_name: STRING
		do
			create some_plane_names.make (0, 15)
			from i := 0 until i > 15 loop
				create some_segment_names.make (0, 255)
				from plane_all_absent := True; j := 0 until j > 255 loop
					create a_segment.make (0, 255)
					from segment_all_absent := True; k := 0 until k > 255 loop
						a_code_point := k + 256 * j + 256 * 256 * i
						a_code_point_datum := code_points.item (a_code_point)
						if a_code_point_datum = Void then
							a_value := -1
						else
							a_value := a_code_point_datum.lower_code
						end
						if a_value /= - 1 then
							segment_all_absent := False; plane_all_absent := False
						end
						a_segment.put (a_value, k)
						k := k + 1
					end
					if segment_all_absent then
						a_segment_array_name := Empty_lower_code_segment_array_name
						if not empty_segment_written then
							empty_segment_written := True
							write_integer_segment (a_segment, Empty_lower_code_segment_array_name, an_output_file)
						end
					else
						a_segment_array_name := "lower_code_plane_" + (i+1).out + "_segment_" + (j+1).out
						write_integer_segment (a_segment, a_segment_array_name, an_output_file)
					end
					some_segment_names.put (a_segment_array_name, j)
					j := j + 1
				end
				if plane_all_absent then
					a_plane_array_name := Empty_lower_code_plane_array_name
					if not empty_plane_written then
						empty_plane_written := True
						write_empty_integer_plane (a_plane_array_name, Empty_lower_code_segment_array_name, an_output_file)
					end
				else
					a_plane_array_name := "lower_code_plane_" + (i+1).out
					write_integer_plane (some_segment_names, a_plane_array_name, an_output_file)
				end
				some_plane_names.put (a_plane_array_name, i)
				i := i + 1
			end
			an_output_file.put_string ("%Tlower_codes: ARRAY [ARRAY [ARRAY [INTEGER]]] is%N")
			an_output_file.put_string ("%T%T%T-- Lower case code points for each code point%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 15)%N")
			from i := 0 until i > 15 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_plane_names.item (i))
				an_output_file.put_string (", ")
				an_output_file.put_string (i.out)
				an_output_file.put_string (")%N")
				i := i + 1
			end
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	write_upper_case_array (an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an Eiffel `ARRAY' containing upper case equivalents.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
		local
			i, j, k, a_code_point, a_value: INTEGER			
			a_code_point_datum: GEUC_UNICODE_DATA
			some_segment_names, some_plane_names: ARRAY [STRING]
			plane_all_absent, segment_all_absent: BOOLEAN
			empty_plane_written, empty_segment_written: BOOLEAN
			a_segment: ARRAY [INTEGER]
			a_plane_array_name, a_segment_array_name: STRING
		do
			create some_plane_names.make (0, 15)
			from i := 0 until i > 15 loop
				create some_segment_names.make (0, 255)
				from plane_all_absent := True; j := 0 until j > 255 loop
					create a_segment.make (0, 255)
					from segment_all_absent := True; k := 0 until k > 255 loop
						a_code_point := k + 256 * j + 256 * 256 * i
						a_code_point_datum := code_points.item (a_code_point)
						if a_code_point_datum = Void then
							a_value := -1
						else
							a_value := a_code_point_datum.upper_code
						end
						if a_value /= - 1 then
							segment_all_absent := False; plane_all_absent := False
						end
						a_segment.put (a_value, k)
						k := k + 1
					end
					if segment_all_absent then
						a_segment_array_name := Empty_upper_code_segment_array_name
						if not empty_segment_written then
							empty_segment_written := True
							write_integer_segment (a_segment, Empty_upper_code_segment_array_name, an_output_file)
						end
					else
						a_segment_array_name := "upper_code_plane_" + (i+1).out + "_segment_" + (j+1).out
						write_integer_segment (a_segment, a_segment_array_name, an_output_file)
					end
					some_segment_names.put (a_segment_array_name, j)
					j := j + 1
				end
				if plane_all_absent then
					a_plane_array_name := Empty_upper_code_plane_array_name
					if not empty_plane_written then
						empty_plane_written := True
						write_empty_integer_plane (a_plane_array_name, Empty_upper_code_segment_array_name, an_output_file)
					end
				else
					a_plane_array_name := "upper_code_plane_" + (i+1).out
					write_integer_plane (some_segment_names, a_plane_array_name, an_output_file)
				end
				some_plane_names.put (a_plane_array_name, i)
				i := i + 1
			end
			an_output_file.put_string ("%Tupper_codes: ARRAY [ARRAY [ARRAY [INTEGER]]] is%N")
			an_output_file.put_string ("%T%T%T-- Upper case code points for each code point%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 15)%N")
			from i := 0 until i > 15 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_plane_names.item (i))
				an_output_file.put_string (", ")
				an_output_file.put_string (i.out)
				an_output_file.put_string (")%N")
				i := i + 1
			end
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end


	write_title_case_array (an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an Eiffel `ARRAY' containing title case equivalents.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
		local
			i, j, k, a_code_point, a_value: INTEGER			
			a_code_point_datum: GEUC_UNICODE_DATA
			some_segment_names, some_plane_names: ARRAY [STRING]
			plane_all_absent, segment_all_absent: BOOLEAN
			empty_plane_written, empty_segment_written: BOOLEAN
			a_segment: ARRAY [INTEGER]
			a_plane_array_name, a_segment_array_name: STRING
		do
			create some_plane_names.make (0, 15)
			from i := 0 until i > 15 loop
				create some_segment_names.make (0, 255)
				from plane_all_absent := True; j := 0 until j > 255 loop
					create a_segment.make (0, 255)
					from segment_all_absent := True; k := 0 until k > 255 loop
						a_code_point := k + 256 * j + 256 * 256 * i
						a_code_point_datum := code_points.item (a_code_point)
						if a_code_point_datum = Void then
							a_value := -1
						else
							a_value := a_code_point_datum.title_code
						end
						if a_value /= - 1 then
							segment_all_absent := False; plane_all_absent := False
						end
						a_segment.put (a_value, k)
						k := k + 1
					end
					if segment_all_absent then
						a_segment_array_name := Empty_title_code_segment_array_name
						if not empty_segment_written then
							empty_segment_written := True
							write_integer_segment (a_segment, Empty_title_code_segment_array_name, an_output_file)
						end
					else
						a_segment_array_name := "title_code_plane_" + (i+1).out + "_segment_" + (j+1).out
						write_integer_segment (a_segment, a_segment_array_name, an_output_file)
					end
					some_segment_names.put (a_segment_array_name, j)
					j := j + 1
				end
				if plane_all_absent then
					a_plane_array_name := Empty_title_code_plane_array_name
					if not empty_plane_written then
						empty_plane_written := True
						write_empty_integer_plane (a_plane_array_name, Empty_title_code_segment_array_name, an_output_file)
					end
				else
					a_plane_array_name := "title_code_plane_" + (i+1).out
					write_integer_plane (some_segment_names, a_plane_array_name, an_output_file)
				end
				some_plane_names.put (a_plane_array_name, i)
				i := i + 1
			end
			an_output_file.put_string ("%Ttitle_codes: ARRAY [ARRAY [ARRAY [INTEGER]]] is%N")
			an_output_file.put_string ("%T%T%T-- Title case code points for each code point%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 15)%N")
			from i := 0 until i > 15 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_plane_names.item (i))
				an_output_file.put_string (", ")
				an_output_file.put_string (i.out)
				an_output_file.put_string (")%N")
				i := i + 1
			end
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	 write_integer8_plane (some_segment_names: ARRAY [STRING]; a_name: STRING; an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for plane `a_name' to `an_output_file'.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
			segment_array_names_not_void: some_segment_names /= Void
			name_not_empty: a_name /= Void and then not a_name.is_empty
		local
			an_index: INTEGER
		do
			an_output_file.put_string ("%T")
			an_output_file.put_string (a_name)
			an_output_file.put_string (": ARRAY [ARRAY [INTEGER_8]] is%N")
			an_output_file.put_string ("%T%T%T-- Generated character class array plane%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 255)%N")
			from  until an_index > 255 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_segment_names.item (an_index))
				an_output_file.put_string (", ")
				an_output_file.put_string (an_index.out)
				an_output_file.put_string (")%N")
				an_index := an_index + 1
			end
			an_output_file.put_string ("%T%Tensure%N")
			an_output_file.put_string ("%T%T%Tresult_not_void: Result /= Void%N")
			an_output_file.put_string ("%T%T%Tsub_arrays_not_void: True -- all items are non-Void%N")
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	write_empty_integer8_plane (a_plane_name, a_segment_name: STRING; an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an empty character-class plane to `an_output_file'.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
			plane_names_not_void: a_plane_name /= Void and then not a_plane_name.is_empty
			segment_name_not_empty: a_segment_name /= Void and then not a_segment_name.is_empty
		local
			an_index: INTEGER
		do
			an_output_file.put_string ("%T")
			an_output_file.put_string (a_plane_name)
			an_output_file.put_string (": ARRAY [ARRAY [INTEGER_8]] is%N")
			an_output_file.put_string ("%T%T%T-- Generated character class array plane%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 255)%N")
			from  until an_index > 255 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (a_segment_name)
				an_output_file.put_string (", ")
				an_output_file.put_string (an_index.out)
				an_output_file.put_string (")%N")
				an_index := an_index + 1
			end
			an_output_file.put_string ("%T%Tensure%N")
			an_output_file.put_string ("%T%T%Tresult_not_void: Result /= Void%N")
			an_output_file.put_string ("%T%T%Tsub_arrays_not_void: True -- all items are non-Void%N")
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end
			
	write_integer8_segment (a_segment: ARRAY [INTEGER_8]; a_segment_array_name: STRING; an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for `a_segment', named `a_segment_array_name' to `an_output_file'.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
			segment_not_void: a_segment /= Void
			segment_array_names_not_void: a_segment_array_name /= Void
		local
			an_index: INTEGER
		do
			an_output_file.put_string ("%T")
			an_output_file.put_string (a_segment_array_name)
			an_output_file.put_string (": ARRAY [INTEGER_8] is%N")
			an_output_file.put_string ("%T%T%T-- Generated character class array segment%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%TResult := string_to_array8 (%"")
			from  until an_index > 255 loop
				an_output_file.put_string ("%%/" + a_segment.item (an_index).out + "/")
				an_index := an_index + 1
			end
			an_output_file.put_string ("%")%N")
			an_output_file.put_string ("%T%Tensure%N")
			an_output_file.put_string ("%T%T%Tresult_not_void: Result /= Void%N")
			an_output_file.put_string ("%T%Tend%N%N")

		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	write_integer_plane (some_segment_names: ARRAY [STRING]; a_name: STRING; an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for plane `a_name' to `an_output_file'.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
			segment_array_names_not_void: some_segment_names /= Void
			name_not_empty: a_name /= Void and then not a_name.is_empty
		local
			an_index: INTEGER
		do
			an_output_file.put_string ("%T")
			an_output_file.put_string (a_name)
			an_output_file.put_string (": ARRAY [ARRAY [INTEGER]] is%N")
			an_output_file.put_string ("%T%T%T-- Generated array plane%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 255)%N")
			from  until an_index > 255 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (some_segment_names.item (an_index))
				an_output_file.put_string (", ")
				an_output_file.put_string (an_index.out)
				an_output_file.put_string (")%N")
				an_index := an_index + 1
			end
			an_output_file.put_string ("%T%Tensure%N")
			an_output_file.put_string ("%T%T%Tresult_not_void: Result /= Void%N")
			an_output_file.put_string ("%T%T%Tsub_arrays_not_void: True -- all items are non-Void%N")
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end

	write_empty_integer_plane (a_plane_name, a_segment_name: STRING; an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for an empty code plane to `an_output_file'.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
			plane_name_not_empty: a_plane_name /= Void and then not a_plane_name.is_empty
			segment_name_not_empty: a_segment_name /= Void and then not a_segment_name.is_empty
		local
			an_index: INTEGER
		do
			an_output_file.put_string ("%T")
			an_output_file.put_string (a_plane_name)
			an_output_file.put_string (": ARRAY [ARRAY [INTEGER]] is%N")
			an_output_file.put_string ("%T%T%T-- Generated array plane%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%Tcreate Result.make (0, 255)%N")
			from  until an_index > 255 loop
				an_output_file.put_string ("%T%T%TResult.put (")
				an_output_file.put_string (a_segment_name)
				an_output_file.put_string (", ")
				an_output_file.put_string (an_index.out)
				an_output_file.put_string (")%N")
				an_index := an_index + 1
			end
			an_output_file.put_string ("%T%Tensure%N")
			an_output_file.put_string ("%T%T%Tresult_not_void: Result /= Void%N")
			an_output_file.put_string ("%T%T%Tsub_arrays_not_void: True -- all items are non-Void%N")
			an_output_file.put_string ("%T%Tend%N%N")
		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end
			
	write_integer_segment (a_segment: ARRAY [INTEGER]; a_segment_array_name: STRING; an_output_file: KL_TEXT_OUTPUT_FILE) is
			-- Write code for `a_segment', named `a_segment_array_name' to `an_output_file'.
		require
			file_open_write: an_output_file /= Void and then an_output_file.is_open_write
			segment_exists: a_segment /= Void
			segment_array_names_not_void: a_segment_array_name /= Void
		local
			an_index: INTEGER
		do
			an_output_file.put_string ("%T")
			an_output_file.put_string (a_segment_array_name)
			an_output_file.put_string (": ARRAY [INTEGER] is%N")
			an_output_file.put_string ("%T%T%T-- Generated array segment%N")
			an_output_file.put_string ("%T%Tonce%N")
			an_output_file.put_string ("%T%T%TResult := <<%N%T%T%TINTEGER_.to_integer (")
			from  until an_index > 255 loop
				an_output_file.put_string (a_segment.item (an_index).out)
				if an_index = 0 then an_output_file.put_string (")") end
				if an_index = 255 then
				   an_output_file.put_string (">>")
				else
					an_output_file.put_string (",")
				end
				if an_index \\ 10 = 0 then an_output_file.put_string ("%N%T%T%T") end
				an_index := an_index + 1
			end
			an_output_file.put_string ("%N")
			an_output_file.put_string ("%T%Tensure%N")
			an_output_file.put_string ("%T%T%Tresult_not_void: Result /= Void%N")
			an_output_file.put_string ("%T%Tend%N%N")

		ensure
			file_still_open: an_output_file /= Void and then an_output_file.is_open_write
		end
						
feature -- Access

	code_points: ARRAY [GEUC_UNICODE_DATA]
			-- Parsed data from "UnicodeData.txt" for each code point;
			-- Not that Unicode does not assign most of the code points
			--  to characters, so many will be `Void'.

	is_range_start (a_name: STRING): BOOLEAN is
			-- Is `a_name' indicating start of range rather than character name?
		require
			name_exists: a_name /= Void
		do
			if a_name.count > 7 and then a_name.substring (a_name.count - 5, a_name.count).is_equal ("First>") then
				Result := True
			end
		end

	is_range_finish (a_name: STRING): BOOLEAN is
			-- Is `a_name' indicating end of range rather than character name?
		require
			name_exists: a_name /= Void
		do
			if a_name.count > 7 and then a_name.substring (a_name.count - 4, a_name.count).is_equal ("Last>") then
				Result := True
			end
		ensure
			at_least_eight_characters_for_range_finish: Result implies a_name.count > 7
		end

feature {NONE} -- Implementation

	error_handler: UT_ERROR_HANDLER
			-- Error handler

	report_general_message (a_message_string: STRING) is
			-- Report a miscellaneous message.
		require
			message_exists: a_message_string /= Void
		local
			an_error: UT_MESSAGE
		do
			create an_error.make (a_message_string)
			error_handler.report_error (an_error)
		end

	initial_code_point: INTEGER
			-- Initial code point for range of characters

invariant

	error_handler_exists: error_handler /= Void

end
	