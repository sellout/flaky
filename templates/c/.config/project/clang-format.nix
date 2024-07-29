## Goals
## • have automated formatting to avoid wasting time editing and debating
## • minimize diff-sensitivity to things like changing function names (e.g.,
##   don’t want whitespace diffs on all the parameter lines)
##
## Decisions
## • break before operators – it’s much easier to understand multi-line
##   expressions when the interior operators are aligned up front
## • no bin-packing – subexpressions at the same level should either _all_ be on
##   one line, or each on their own line for readability, bin packing makes it
##   easy to miss elements
#
# NB: If clang-format can’t parse this file (or doesn’t understand any of the
#     values), it will format with the default settings. If this happens it’s
#     important to _revert_ the formatting, not just reformat after fixing it.
#     This is because some formatting changes aren’t reversible, so you may
#     introduce formatting regressions if you simply reformat.
#
# NB: Any disabling of auto-formatting needs a justification. This can be
#     provided like
#
#     // clang-format off: why we’re disabling
{lib, ...}: let
  indentWidth = 2;
in {
  ## C/C++/Java/JavaScript/Objective-C/Protobuf/C# formatter
  programs.treefmt.programs.clang-format.enable = true;
  project.file.".clang-format".text = lib.generators.toYAML {} {
    ## TODO: I’m not really sure how much my style aligns with any particular style,
    ##       but it might be good to fall back to one for the cases where I don’t
    ##       have a strong opinion, leaving this file clearer in its intent.
    # BasedOnStyle = "LLVM";

    AccessModifierOffset = 0; # ignored anyway, because of `IndentAccessModifiers`
    AlignAfterOpenBracket = "AlwaysBreak"; # prevents spurious whitespace diffs
    AlignArrayOfStructures = "None"; # prevents spurious whitespace diffs
    AlignConsecutiveAssignments = "None"; # prevents spurious whitespace diffs
    AlignConsecutiveBitFields = "None"; # prevents spurious whitespace diffs
    AlignConsecutiveDeclarations = "None"; # prevents spurious whitespace diffs
    AlignConsecutiveMacros = "None"; # prevents spurious whitespace diffs
    AlignEscapedNewlines = "DontAlign"; # prevents spurious whitespace diffs
    AlignOperands = "DontAlign"; # prevents spurious whitespace diffs
    AlignTrailingComments = "Never"; # prevents spurious whitespace diffs
    AllowAllArgumentsOnNextLine = true; # compact
    AllowAllConstructorInitializersOnNextLine = true; # compact
    AllowAllParametersOfDeclarationOnNextLine = true; # compact
    AllowShortBlocksOnASingleLine = "Always"; # compact
    AllowShortCaseLabelsOnASingleLine = true; # compact
    AllowShortFunctionsOnASingleLine = "All"; # compact
    AllowShortIfStatementsOnASingleLine = "WithoutElse"; # compact, but consistent
    AllowShortLambdasOnASingleLine = "All"; # compact
    AllowShortLoopsOnASingleLine = true; # compact
    AlwaysBreakAfterReturnType = "None"; # compact
    AlwaysBreakBeforeMultilineStrings = true; # consistent
    AlwaysBreakTemplateDeclarations = "Yes"; # uncertain, but seems like they should be more like a block
    BinPackArguments = false; # consistent
    BinPackParameters = false; # consistent
    BitFieldColonSpacing = "Both"; # consistent
    BreakAfterAttributes = "Never"; # uncertain, but compact
    BreakAfterJavaFieldAnnotations = false; # uncertain, but compact
    BreakArrays = false; # only for JSON, but compact
    BreakBeforeBinaryOperators = "All"; # consistent
    BreakBeforeBraces = "Attach"; # compact & consistent
    BreakBeforeConceptDeclarations = "Always"; # seems redundant with AlwaysBreakTemplateDeclarations
    BreakBeforeInlineASMColon = "OnlyMultiline"; # compact & consistent
    BreakBeforeTernaryOperators = true; # consistent
    BreakConstructorInitializers = "BeforeColon"; # consistent
    BreakInheritanceList = "BeforeColon"; # consistent
    BreakStringLiterals = false; # these should be manually broken … but maybe play with the long-line penalty
    ColumnLimit = 80;
    CompactNamespaces = false; # consistent with avoiding bin packing
    ConstructorInitializerIndentWidth = indentWidth; # consistent
    ContinuationIndentWidth = indentWidth; # TODO: maybe make this different from IndentWidth to allow distinctions in first line of function or after long if conditional
    Cpp11BracedListStyle = true; # consistent with function call style (see doc), even if inconsistent with other braces
    DerivePointerAlignment = false; # non-Wadler
    DisableFormat = false;
    EmptyLineAfterAccessModifier = "Never";
    EmptyLineBeforeAccessModifier = "Always";
    FixNamespaceComments = false; # I don’t support maintaining standardized comments
    IncludeBlocks = "Regroup";
    # NB: It’s important to format includes “inside out” to minimize the impact they can have on each
    #     other. See https://llvm.org/docs/CodingStandards.html#include-style for more.
    #
    #     However, here we only categorize the parts that can be identified syntactically. Any
    #     sub-ordering would be project-specific.
    IncludeCategories = [
      {
        Regex = "<[^/.]+>";
        Priority = 3;
      } # system
      {
        Regex = "<.*>";
        Priority = 2;
      } # third-party
      {
        Regex = ".*";
        Priority = 1;
      } # local
    ];
    IndentAccessModifiers = true; # consistent
    IndentCaseBlocks = true; # consistent, case blocks aren’t blocks, they only scope, so don’t format like blocks
    IndentCaseLabels = true; # consistent
    IndentExternBlock = "Indent"; # consistent
    IndentFunctionDeclarationAfterType = false;
    IndentGotoLabels = false; # should never use this anyway, but they are not part of the containing block
    IndentPPDirectives = "AfterHash";
    IndentRequiresClause = true; # TODO: Don’t know why this doesn’t have an effect with `RequiresClausePosition: WithPreceding`
    IndentWidth = indentWidth;
    IndentWrappedFunctionNames = true; # consistent (but uncommon)
    InsertBraces = true; # consistent, avoids accidentally breaking control flow when an additional statement is added
    InsertNewlineAtEOF = true; # POSIX!
    InsertTrailingCommas = "Wrapped"; # consistent, prevents spurious whitespace diffs
    IntegerLiteralSeparator = {
      # readability (although 8-digit groups may be too large)
      Binary = 8; # byte
      Decimal = 3; # many standards, see https://en.wikipedia.org/wiki/Decimal_separator#Digit_grouping
      Hex = 8; # common machine word (64b)
    };
    JavaImportGroups = []; # unimportant, unlike C includes
    JavaScriptQuotes = "Double"; # consistent with interpolated strings elsewhere, interior quotes should be non-ASCII when possible, escaped otherwise
    KeepEmptyLinesAtTheStartOfBlocks = true; # TODO: Change to false if we can get indentation to be non-ambiguous
    # Language = "Cpp"; # should be used for all, unless we have alternative better formatters to use for specific languages
    MaxEmptyLinesToKeep = 1; # multiple breaks usually indicates sections, which should have intervening docs or comments instead
    NamespaceIndentation = "All"; # consistent
    ObjCBinPackProtocolList = "Never"; # no bin packing
    ObjCBlockIndentWidth = indentWidth; # same as IndentWidth
    ObjCBreakBeforeNestedBlockParam = true; # consistent
    ObjCSpaceAfterProperty = false; # consistent
    ObjCSpaceBeforeProtocolList = false; # consistent
    PackConstructorInitializers = "NextLine"; # consistent
    ## Add penalties if necessary. Some guidelines:
    ## • break after return type before breaking arguments
    PenaltyBreakOpenParenthesis = 1;
    PenaltyReturnTypeOnItsOwnLine = 0;
    PointerAlignment = "Right"; # because `Foo *x` means “`*x` is a `Foo`”
    QualifierAlignment = "Custom";
    ## consistent, specifically `const Foo * const *` is worse than `Foo const * const *`
    ## TODO: are _all_ of these correct?
    ## • `const volatile` is a common pairing, so that makes sense
    ## • `restrict` logically goes with `const` and `volatile` (but is it correct in that order)
    ## • `constexpr` implies both `const` and `inline`, but it applies to the declaration, not the type, so it belongs with `inline`, but the order of the two doesn’t matter, as long as they’re adjacent
    QualifierOrder = [
      "constexpr"
      "inline"
      "static"
      "type"
      "const"
      "volatile"
      "restrict"
    ];
    ReflowComments = true; # Wadler
    RemoveBracesLLVM = false; # consistent with InsertBraces
    RequiresClausePosition = "SingleLine"; # compact & consistent
    SeparateDefinitionBlocks = "Always"; # consistent
    SortIncludes = "CaseInsensitive"; # consistent with SortUsingDeclarations
    SortUsingDeclarations = true; # consistent
    SpaceAfterCStyleCast = false; # TODO: not sure, feels inconsistent, but it’s an important distinction from other parens
    SpaceAfterLogicalNot = false; # consistent
    SpaceAfterTemplateKeyword = false; # consistent with function style
    SpaceAroundPointerQualifiers = "Both"; # TODO: Default may be more consistent
    SpaceBeforeAssignmentOperators = true; # consistent with boolean operators
    SpaceBeforeCaseColon = false; # consistent with comma, but inconsistent with other colons – TOOD: reconsider
    SpaceBeforeCpp11BracedList = false; # consistent with function call syntax (see Cpp11BracedListStyle doc)
    SpaceBeforeCtorInitializerColon = true; # consistent with operators, and line breaking, but not with some other colons – TODO: reconsider
    SpaceBeforeParens = "ControlStatementsExceptControlMacros"; # TODO: reconsider
    SpaceBeforeRangeBasedForLoopColon = true; #TODO: consider with other colons
    SpaceBeforeSquareBrackets = false; # consistent with function call syntax
    SpaceInEmptyBlock = false; # consistent with other empty pairs
    SpaceInEmptyParentheses = false;
    SpacesBeforeTrailingComments = 1; # consistent
    SpacesInAngles = "Never"; # consistent with function call syntax
    SpacesInCStyleCastParentheses = false; # consistent
    SpacesInContainerLiterals = false; # consistent
    SpacesInLineCommentPrefix = {
      Minimum = 1;
      Maximum = 1;
    }; # consistent
    SpacesInParentheses = false; # consistent
    SpacesInSquareBrackets = false; # consistent
    Standard = "c++20";
    TabWidth = 1 + 2 * indentWidth;
    UseCRLF = false;
    UseTab = "Never";
  };
}
