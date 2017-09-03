#coding:UTF-8
from pyparsing import *

line_comment = Regex('#.*')
identifier = Regex('[A-Za-z_][A-Za-z0-9_]*')
#identifier = Combine(Word(alphas) + ZeroOrMore(Word(alphanums+'_')))

lpar=Word('(')
rpar=Word(')')

######### cmake 3.6.1 Normal Commands #########
key_add_compile_options = Keyword("add_compile_options",caseless=True)
key_add_custom_command = Keyword("add_custom_command",caseless=True)
key_add_custom_target = Keyword("add_custom_target",caseless=True)
key_add_definitions = Keyword("add_definitions",caseless=True)
key_add_dependencies = Keyword("add_dependencies",caseless=True)
key_add_executable = Keyword("add_executable",caseless=True)
key_add_library = Keyword("add_library",caseless=True)
key_add_subdirectory = Keyword("add_subdirectory",caseless=True)
key_add_test = Keyword("add_test",caseless=True)
key_aux_source_directory = Keyword("aux_source_directory",caseless=True)
key_break = Keyword("break",caseless=True)
key_build_command = Keyword("build_command",caseless=True)
key_cmake_host_system_information = Keyword("cmake_host_system_information",caseless=True)
key_cmake_minimum_required = Keyword("cmake_minimum_required",caseless=True)
key_cmake_parse_arguments = Keyword("cmake_parse_arguments",caseless=True)
key_cmake_policy = Keyword("cmake_policy",caseless=True)
key_endfunction = Keyword("endfunction",caseless=True)
key_function = Keyword("function",caseless=True)
key_elseif =  Keyword("elseif",caseless=True)
key_else = Keyword("else",caseless=True)
key_endif =  Keyword("endif",caseless=True)
key_if =  Keyword("if",caseless=True)
key_endmacro = Keyword("endmacro",caseless=True)
key_macro =  Keyword("macro",caseless=True)
key_foreach =  Keyword("foreach",caseless=True)
key_endwhile =  Keyword("endwhile",caseless=True)
key_while =  Keyword("while",caseless=True)

if __name__ == "__main__":
    print line_comment.parseString("############")
    print identifier.parseString("a")
    print identifier.parseString("a_9")
    print lpar.parseString("((((((")