import { Template } from '../types';

export class TemplateSelector {
  /**
   * Selects an enabled template based on weight or uniform distribution.
   */
  static selectTemplate(
    templates: Template[],
    strategy: 'weighted' | 'uniform' = 'weighted'
  ): Template | null {
    const eligible = templates.filter((t) => t.isEnabled);
    if (eligible.length === 0) return null;

    if (strategy === 'uniform') {
      const idx = Math.floor(Math.random() * eligible.length);
      return eligible[idx];
    }

    const totalWeight = eligible.reduce((sum, t) => sum + Math.max(1, t.weight), 0);
    let randomVal = Math.floor(Math.random() * totalWeight);

    for (const tmpl of eligible) {
      const weight = Math.max(1, tmpl.weight);
      if (randomVal < weight) {
        return tmpl;
      }
      randomVal -= weight;
    }

    return eligible[0];
  }

  /**
   * Generates a random delay in seconds between min and max inclusive.
   */
  static generateRandomDelay(minSeconds: number, maxSeconds: number): number {
    const min = Math.max(1, Math.min(minSeconds, maxSeconds));
    const max = Math.max(min, maxSeconds);
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  /**
   * Interpolates variables into title and body.
   */
  static render(
    template: Template,
    customVariables: Record<string, string> = {}
  ): { title: string; body: string; isSimulated: boolean } {
    const randomOrderId = Math.floor(1000 + Math.random() * 9000).toString();
    const randomAmount = (15 + Math.random() * 120).toFixed(2);
    const randomItems = Math.floor(1 + Math.random() * 3).toString();

    const mergedVars: Record<string, string> = {
      order_id: randomOrderId,
      amount: `$${randomAmount}`,
      items: randomItems,
      store: 'Online Store · Paya Ecom',
      currency: 'USD',
      ...(template.defaultVariables || {}),
      ...customVariables,
    };

    let title = template.title;
    let body = template.body;

    for (const [key, value] of Object.entries(mergedVars)) {
      const pattern = new RegExp(`{{${key}}}`, 'g');
      title = title.replace(pattern, value);
      body = body.replace(pattern, value);
    }

    return {
      title,
      body,
      isSimulated: template.isSimulated,
    };
  }
}
