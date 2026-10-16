/** Financial reconciliation stays held until its final database acceptance is completed. */
export function legacyReconciliationReadiness(): {canReconcile:boolean;message:string} {
 return {canReconcile:false,message:'A conferência está disponível. A aplicação dos ajustes de pedidos e estoque aguarda a validação transacional final.'};
}
export function assertLegacyReconciliationReady():void {
 const state=legacyReconciliationReadiness();
 if(!state.canReconcile)throw new Error(state.message);
}
