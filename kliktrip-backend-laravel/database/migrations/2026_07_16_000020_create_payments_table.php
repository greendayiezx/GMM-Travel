<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('payable_id');
            $table->string('payable_type');
            $table->string('invoice_number')->unique();
            $table->string('gateway');
            $table->string('gateway_transaction_id')->nullable();
            $table->string('snap_token')->nullable();
            $table->json('payment_instructions')->nullable();
            $table->string('payment_method');
            $table->decimal('gross_amount', 12, 2);
            $table->decimal('admin_fee', 12, 2)->default(0);
            $table->decimal('discount', 12, 2)->default(0);
            $table->decimal('total_amount', 12, 2);
            $table->enum('status', ['PENDING', 'SUCCESS', 'FAILED', 'EXPIRED', 'REFUNDED'])->default('PENDING');
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('expired_at')->nullable();
            $table->timestamps();

            $table->index(['payable_id', 'payable_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
