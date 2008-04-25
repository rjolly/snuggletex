/* $Id: EnvironmentToken.java,v 1.4 2008/04/14 10:48:25 dmckain Exp $
 *
 * Copyright 2008 University of Edinburgh.
 * All Rights Reserved
 */
package uk.ac.ed.ph.snuggletex.tokens;

import uk.ac.ed.ph.aardvark.commons.util.DumpMode;
import uk.ac.ed.ph.aardvark.commons.util.ObjectDumperOptions;
import uk.ac.ed.ph.snuggletex.conversion.FrozenSlice;
import uk.ac.ed.ph.snuggletex.definitions.BuiltinEnvironment;
import uk.ac.ed.ph.snuggletex.definitions.LaTeXMode;

/**
 * @author  David McKain
 * @version $Revision: 1.4 $
 */
public final class EnvironmentToken extends FlowToken {
    
    private final BuiltinEnvironment environment;
    private final ArgumentContainerToken optionalArgument;
    private final ArgumentContainerToken[] arguments;
    private final ArgumentContainerToken content;
    
    public EnvironmentToken(final FrozenSlice slice, final LaTeXMode latexMode,
            final BuiltinEnvironment environment, final ArgumentContainerToken content) {
        this(slice, latexMode, environment, null, ArgumentContainerToken.EMPTY_ARRAY, content);
    }
    
    public EnvironmentToken(final FrozenSlice slice, final LaTeXMode latexMode,
            final BuiltinEnvironment environment, final ArgumentContainerToken optionalArgument,
            final ArgumentContainerToken[] arguments, final ArgumentContainerToken content) {
        super(slice, TokenType.ENVIRONMENT, latexMode, environment.getInterpretation(), environment.getTextFlowContext());
        this.environment = environment;
        this.optionalArgument = optionalArgument;
        this.arguments = arguments;
        this.content = content;
    }

    public BuiltinEnvironment getEnvironment() {
        return environment;
    }
    
    @ObjectDumperOptions(DumpMode.DEEP)
    public ArgumentContainerToken getOptionalArgument() {
        return optionalArgument;
    }
    
    @ObjectDumperOptions(DumpMode.DEEP)
    public ArgumentContainerToken[] getArguments() {
        return arguments;
    }
    
    @ObjectDumperOptions(DumpMode.DEEP)
    public ArgumentContainerToken getContent() {
        return content;
    }
}
