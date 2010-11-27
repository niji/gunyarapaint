package com.github.niji.gunyarapaint.ui.errors
{
    public final class DecryptError extends Error
    {
        public function DecryptError(message:*="", id:*=0)
        {
            name = "DecryptError";
            super(message, id);
        }
    }
}
